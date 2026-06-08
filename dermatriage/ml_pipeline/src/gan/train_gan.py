"""Conditional WGAN-GP training loop for dark-skin image synthesis.

Trains a ConditionalGenerator / ConditionalCritic pair on the Fitzpatrick17k
subset restricted to skin types IV, V and VI, conditioned on (skin type,
disease) one-hot vectors. Wasserstein distance and an FID approximation are
tracked; the lowest-FID checkpoint is kept as best.
"""

from pathlib import Path

import numpy as np
import pandas as pd
import torch
import torch.nn.functional as F
from PIL import Image
from torch.utils.data import DataLoader, Dataset
from torchvision import transforms

try:  # FID matrix square root; scipy is a project dependency.
    from scipy import linalg
except ImportError:  # pragma: no cover
    linalg = None

try:  # Optional richer logging.
    import wandb
except ImportError:  # pragma: no cover
    wandb = None

from ..utils.logger import get_logger
from .discriminator import ConditionalCritic
from .generator import ConditionalGenerator
from .wgan_gp import compute_gradient_penalty

logger = get_logger(__name__)


# ----------------------------------------------------------------------------
# Dataset: Fitzpatrick17k subset (types IV/V/VI), images scaled to [-1, 1].
# ----------------------------------------------------------------------------
class GANConditionDataset(Dataset):
    """Serves (image, condition) pairs for conditional GAN training.

    The condition vector concatenates a one-hot Fitzpatrick skin type (over
    ``fitzpatrick_classes``) with a one-hot disease code (over the first
    ``disease_classes`` harmonised labels seen in the subset).
    """

    def __init__(self, df, image_size, fitz_classes, disease_classes):
        self.df = df.reset_index(drop=True)
        self.image_size = image_size
        self.fitz_classes = list(fitz_classes)
        self.disease_classes = disease_classes
        self.fitz_to_idx = {ft: i for i, ft in enumerate(self.fitz_classes)}

        # Map raw harmonised label ids -> contiguous disease indices [0, K).
        unique_labels = sorted(self.df["label_idx"].unique())
        self.disease_to_idx = {lab: i for i, lab in enumerate(unique_labels)}

        self.transform = transforms.Compose(
            [
                transforms.Resize((image_size, image_size)),
                transforms.ToTensor(),
                transforms.Normalize([0.5] * 3, [0.5] * 3),  # -> [-1, 1]
            ]
        )

    @property
    def condition_dim(self):
        return len(self.fitz_classes) + self.disease_classes

    def encode_condition(self, fitz_type, label_idx):
        """Build a one-hot (fitz | disease) condition vector."""
        cond = torch.zeros(self.condition_dim)
        cond[self.fitz_to_idx[fitz_type]] = 1.0
        disease_idx = self.disease_to_idx[label_idx]
        cond[len(self.fitz_classes) + disease_idx] = 1.0
        return cond

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        image = Image.open(row["image_path"]).convert("RGB")
        image = self.transform(image)
        condition = self.encode_condition(
            int(row["fitzpatrick_type"]), int(row["label_idx"])
        )
        return image, condition


def _load_dark_skin_subset(cfg):
    """Read the train manifest and keep only the dark Fitzpatrick subset."""
    gan_cfg = cfg["gan"]
    processed_root = Path(cfg["data"]["processed_path"])
    manifest = processed_root / "train" / "manifest.csv"
    df = pd.read_csv(manifest)

    fitz_classes = gan_cfg["fitzpatrick_classes"]
    subset = df[df["fitzpatrick_type"].isin(fitz_classes)].copy()

    # Restrict to the configured number of disease classes (most frequent).
    disease_classes = gan_cfg["disease_classes"]
    top_labels = (
        subset["label_idx"].value_counts().nlargest(disease_classes).index
    )
    subset = subset[subset["label_idx"].isin(top_labels)].copy()

    logger.info(
        "GAN subset: %d images across Fitzpatrick %s and %d disease classes",
        len(subset),
        fitz_classes,
        subset["label_idx"].nunique(),
    )
    return subset


# ----------------------------------------------------------------------------
# Simple FID approximation (no external pytorch_fid dependency).
# ----------------------------------------------------------------------------
def _image_features(imgs):
    """Cheap feature embedding: downsample to 16x16 RGB and flatten.

    This is a lightweight proxy for Inception features — enough to track
    relative generation quality across epochs, not a publication-grade FID.
    """
    feats = F.adaptive_avg_pool2d(imgs, output_size=16)
    return feats.reshape(feats.size(0), -1).detach().cpu().numpy()


def _frechet_distance(feat_real, feat_fake):
    """Fréchet distance between two Gaussian-approximated feature sets."""
    mu_r, mu_f = feat_real.mean(0), feat_fake.mean(0)
    sigma_r = np.cov(feat_real, rowvar=False)
    sigma_f = np.cov(feat_fake, rowvar=False)

    diff = mu_r - mu_f
    if linalg is None:  # Fallback: drop the covariance cross-term.
        return float(diff.dot(diff) + np.trace(sigma_r + sigma_f))

    covmean, _ = linalg.sqrtm(sigma_r.dot(sigma_f), disp=False)
    if np.iscomplexobj(covmean):
        covmean = covmean.real
    return float(diff.dot(diff) + np.trace(sigma_r + sigma_f - 2.0 * covmean))


@torch.no_grad()
def _estimate_fid(generator, loader, z_dim, device, max_batches=8):
    """Estimate FID between real batches and generator samples."""
    generator.eval()
    real_feats, fake_feats = [], []
    for i, (real_imgs, condition) in enumerate(loader):
        if i >= max_batches:
            break
        real_imgs = real_imgs.to(device)
        condition = condition.to(device)
        z = torch.randn(real_imgs.size(0), z_dim, device=device)
        fake_imgs = generator(z, condition)
        real_feats.append(_image_features(real_imgs))
        fake_feats.append(_image_features(fake_imgs))
    generator.train()

    feat_real = np.concatenate(real_feats, axis=0)
    feat_fake = np.concatenate(fake_feats, axis=0)
    return _frechet_distance(feat_real, feat_fake)


# ----------------------------------------------------------------------------
# Checkpointing
# ----------------------------------------------------------------------------
def _save_gan_checkpoint(path, generator, critic, opt_g, opt_d, epoch, metrics):
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    torch.save(
        {
            "generator_state_dict": generator.state_dict(),
            "critic_state_dict": critic.state_dict(),
            "opt_g_state_dict": opt_g.state_dict(),
            "opt_d_state_dict": opt_d.state_dict(),
            "epoch": epoch,
            "metrics": metrics,
        },
        path,
    )


def _log(metrics, step):
    """Log to wandb if a run is active; always emit to the logger."""
    logger.info(
        "epoch %d | W-dist %.4f | FID %s",
        step,
        metrics.get("wasserstein", float("nan")),
        f"{metrics['fid']:.4f}" if "fid" in metrics else "n/a",
    )
    if wandb is not None and wandb.run is not None:
        wandb.log(metrics, step=step)


# ----------------------------------------------------------------------------
# Training
# ----------------------------------------------------------------------------
def train_wgan_gp(cfg, device):
    """Train the conditional WGAN-GP and return run summary info.

    Args:
        cfg: Full pipeline config dict.
        device: Torch device to train on.

    Returns:
        dict: ``{"best_fid", "best_epoch", "best_checkpoint", "last_checkpoint"}``.
    """
    gan_cfg = cfg["gan"]
    z_dim = gan_cfg["z_dim"]
    n_critic = gan_cfg["n_critic"]
    lambda_gp = gan_cfg["lambda_gp"]
    epochs = gan_cfg["epochs"]
    checkpoint_every = gan_cfg["checkpoint_every"]
    ckpt_dir = Path(gan_cfg.get("checkpoint_dir", "models/gan"))

    # --- Data ---
    subset = _load_dark_skin_subset(cfg)
    dataset = GANConditionDataset(
        subset,
        image_size=cfg["data"]["image_size"],
        fitz_classes=gan_cfg["fitzpatrick_classes"],
        disease_classes=gan_cfg["disease_classes"],
    )
    loader = DataLoader(
        dataset,
        batch_size=gan_cfg["batch_size"],
        shuffle=True,
        num_workers=4,
        pin_memory=True,
        drop_last=True,
    )
    condition_dim = dataset.condition_dim

    # --- Models & optimisers ---
    generator = ConditionalGenerator(
        z_dim=z_dim, condition_dim=condition_dim,
        img_size=cfg["data"]["image_size"],
    ).to(device)
    critic = ConditionalCritic(condition_dim=condition_dim).to(device)

    betas = (gan_cfg["beta1"], gan_cfg["beta2"])
    opt_g = torch.optim.Adam(generator.parameters(), lr=gan_cfg["lr_g"], betas=betas)
    opt_d = torch.optim.Adam(critic.parameters(), lr=gan_cfg["lr_d"], betas=betas)

    best_fid = float("inf")
    best_epoch = -1
    best_ckpt = ckpt_dir / "generator_best.pt"
    last_ckpt = ckpt_dir / "generator_last.pt"

    for epoch in range(1, epochs + 1):
        generator.train()
        critic.train()
        wasserstein_running = 0.0
        critic_steps = 0

        for i, (real_imgs, condition) in enumerate(loader):
            real_imgs = real_imgs.to(device)
            condition = condition.to(device)
            bs = real_imgs.size(0)

            # --- Critic step ---
            z = torch.randn(bs, z_dim, device=device)
            fake_imgs = generator(z, condition).detach()

            critic_real = critic(real_imgs, condition).mean()
            critic_fake = critic(fake_imgs, condition).mean()
            gp = compute_gradient_penalty(
                critic, real_imgs, fake_imgs, condition, device, lambda_gp
            )
            loss_d = critic_fake - critic_real + gp

            opt_d.zero_grad(set_to_none=True)
            loss_d.backward()
            opt_d.step()

            wasserstein_running += (critic_real - critic_fake).item()
            critic_steps += 1

            # --- Generator step (once every n_critic critic steps) ---
            if (i + 1) % n_critic == 0:
                z = torch.randn(bs, z_dim, device=device)
                gen_imgs = generator(z, condition)
                loss_g = -critic(gen_imgs, condition).mean()

                opt_g.zero_grad(set_to_none=True)
                loss_g.backward()
                opt_g.step()

        metrics = {
            "wasserstein": wasserstein_running / max(critic_steps, 1),
            "epoch": epoch,
        }

        # --- Periodic FID / logging ---
        if epoch % 10 == 0 or epoch == epochs:
            fid = _estimate_fid(generator, loader, z_dim, device)
            metrics["fid"] = fid
            if fid < best_fid:
                best_fid = fid
                best_epoch = epoch
                _save_gan_checkpoint(
                    best_ckpt, generator, critic, opt_g, opt_d, epoch, metrics
                )
                logger.info("New best FID %.4f at epoch %d", fid, epoch)

        _log(metrics, step=epoch)

        # --- Periodic checkpoint ---
        if epoch % checkpoint_every == 0 or epoch == epochs:
            _save_gan_checkpoint(
                ckpt_dir / f"generator_epoch{epoch}.pt",
                generator, critic, opt_g, opt_d, epoch, metrics,
            )

    # Always persist the final state.
    _save_gan_checkpoint(
        last_ckpt, generator, critic, opt_g, opt_d, epochs,
        {"wasserstein": metrics.get("wasserstein"), "epoch": epochs},
    )

    logger.info("Training done. Best FID %.4f at epoch %d", best_fid, best_epoch)
    return {
        "best_fid": best_fid,
        "best_epoch": best_epoch,
        "best_checkpoint": str(best_ckpt),
        "last_checkpoint": str(last_ckpt),
    }
