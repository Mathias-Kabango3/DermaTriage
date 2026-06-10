#!/usr/bin/env python
"""Train the EfficientNet-B4 teacher.

Strategy:
    * Warm-up: backbone frozen (only deepest blocks + head train) for the first
      ``freeze_epochs`` epochs, then the whole network is unfrozen.
    * AdamW + CosineAnnealingLR, label-smoothed cross-entropy.
    * Mixed-precision training on CUDA.
    * Best checkpoint selected by validation accuracy; per-Fitzpatrick accuracy
      tracked for equity monitoring.

Run from the ml_pipeline/ directory:
    python scripts/03_train_teacher.py --config config.yaml
"""

import argparse
import sys
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.optim.lr_scheduler import CosineAnnealingLR

# Make the project package importable when run as a script.
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from src.data.dataloader import build_dataloaders  # noqa: E402
from src.models.teacher import build_teacher, freeze_backbone  # noqa: E402
from src.utils.checkpoint import save_checkpoint  # noqa: E402
from src.utils.config import load_config  # noqa: E402
from src.utils.logger import get_logger, init_wandb  # noqa: E402
from src.utils.seed import set_seed  # noqa: E402

logger = get_logger(__name__)

# Epochs to keep the backbone frozen during warm-up.
DEFAULT_FREEZE_EPOCHS = 10


def train_one_epoch(model, loader, optimizer, criterion, device, scaler):
    """Run one training epoch. Returns (avg_loss, accuracy)."""
    model.train()
    use_amp = device.type == "cuda"

    running_loss = 0.0
    correct = 0
    total = 0

    for batch in loader:
        images = batch["image"].to(device, non_blocking=True)
        labels = batch["label"].to(device, non_blocking=True)

        optimizer.zero_grad(set_to_none=True)
        with torch.autocast(device_type=device.type, enabled=use_amp):
            logits = model(images)
            loss = criterion(logits, labels)

        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()

        running_loss += loss.item() * labels.size(0)
        correct += (logits.argmax(dim=1) == labels).sum().item()
        total += labels.size(0)

    return running_loss / max(total, 1), correct / max(total, 1)


@torch.no_grad()
def validate(model, loader, device):
    """Evaluate on the validation set.

    Returns:
        tuple: ``(avg_loss, accuracy, fitzpatrick_accuracies)`` where the last
        item maps each Fitzpatrick type to its accuracy.
    """
    model.eval()

    running_loss = 0.0
    correct = 0
    total = 0
    fitz_correct = {}
    fitz_total = {}

    for batch in loader:
        images = batch["image"].to(device, non_blocking=True)
        labels = batch["label"].to(device, non_blocking=True)
        fitz = batch["fitzpatrick"]

        logits = model(images)
        loss = F.cross_entropy(logits, labels)

        preds = logits.argmax(dim=1)
        running_loss += loss.item() * labels.size(0)
        correct += (preds == labels).sum().item()
        total += labels.size(0)

        correct_mask = (preds == labels).cpu()
        for ft, is_correct in zip(fitz.tolist(), correct_mask.tolist()):
            fitz_total[ft] = fitz_total.get(ft, 0) + 1
            fitz_correct[ft] = fitz_correct.get(ft, 0) + int(is_correct)

    fitz_acc = {
        ft: fitz_correct[ft] / fitz_total[ft] for ft in sorted(fitz_total)
    }
    return running_loss / max(total, 1), correct / max(total, 1), fitz_acc


def _make_optimizer_and_scheduler(model, cfg, total_epochs):
    """AdamW over trainable params + cosine schedule across ``total_epochs``."""
    teacher_cfg = cfg["teacher"]
    params = [p for p in model.parameters() if p.requires_grad]
    optimizer = torch.optim.AdamW(
        params,
        lr=teacher_cfg["lr"],
        weight_decay=teacher_cfg["weight_decay"],
    )
    scheduler = CosineAnnealingLR(optimizer, T_max=max(total_epochs, 1))
    return optimizer, scheduler


def main():
    parser = argparse.ArgumentParser(description="Train the DermaTriage teacher.")
    parser.add_argument("--config", default="config.yaml", help="Path to config.")
    parser.add_argument(
        "--no-wandb", action="store_true", help="Disable Weights & Biases logging."
    )
    args = parser.parse_args()

    cfg = load_config(args.config)
    set_seed()

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    teacher_cfg = cfg["teacher"]
    epochs = teacher_cfg["epochs"]
    freeze_epochs = teacher_cfg.get("freeze_epochs", DEFAULT_FREEZE_EPOCHS)
    logger.info(
        "Training on HAM10000 only (%d classes). Fitzpatrick-stratified "
        "metrics disabled until Fitzpatrick17k is available.",
        cfg["data"]["num_classes"],
    )
    logger.info("Training teacher on %s for %d epochs", device, epochs)

    run = None
    if not args.no_wandb:
        run = init_wandb(cfg, job_type="train_teacher")
        if run is not None:
            # Label the run so HAM10000-only results are clearly distinguished.
            run.name = f"teacher_ham10000_only_{run.id}"

    # --- Data ---
    train_loader, val_loader, _ = build_dataloaders(
        cfg, batch_size=teacher_cfg["batch_size"]
    )

    # --- Model ---
    model = build_teacher(
        num_classes=cfg["data"]["num_classes"],
        pretrained=teacher_cfg["pretrained"],
    ).to(device)
    freeze_backbone(model)  # warm-up: backbone frozen
    frozen = True

    criterion = nn.CrossEntropyLoss(label_smoothing=teacher_cfg["label_smoothing"])
    scaler = torch.cuda.amp.GradScaler(enabled=device.type == "cuda")

    # Optimiser/scheduler for the frozen warm-up phase.
    optimizer, scheduler = _make_optimizer_and_scheduler(model, cfg, freeze_epochs)

    ckpt_dir = Path(teacher_cfg.get("checkpoint_dir", "models/teacher"))
    best_ckpt = ckpt_dir / "teacher_best.pt"
    best_val_acc = 0.0
    best_epoch = -1
    best_fitz_acc = {}

    for epoch in range(1, epochs + 1):
        # Unfreeze the whole backbone once warm-up is done.
        if frozen and epoch > freeze_epochs:
            logger.info("Epoch %d: unfreezing full backbone", epoch)
            for p in model.parameters():
                p.requires_grad = True
            optimizer, scheduler = _make_optimizer_and_scheduler(
                model, cfg, epochs - freeze_epochs
            )
            frozen = False

        train_loss, train_acc = train_one_epoch(
            model, train_loader, optimizer, criterion, device, scaler
        )
        val_loss, val_acc, fitz_acc = validate(model, val_loader, device)
        scheduler.step()

        logger.info(
            "Epoch %d/%d | train loss %.4f acc %.4f | val loss %.4f acc %.4f",
            epoch, epochs, train_loss, train_acc, val_loss, val_acc,
        )

        metrics = {
            "train/loss": train_loss,
            "train/accuracy": train_acc,
            "val/loss": val_loss,
            "val/accuracy": val_acc,
            "lr": optimizer.param_groups[0]["lr"],
            "epoch": epoch,
        }
        for ft, acc in fitz_acc.items():
            metrics[f"val/fitzpatrick_{ft}_accuracy"] = acc
        if run is not None:
            run.log(metrics, step=epoch)

        if val_acc > best_val_acc:
            best_val_acc = val_acc
            best_epoch = epoch
            best_fitz_acc = fitz_acc
            save_checkpoint(
                model, optimizer, epoch,
                {"val_accuracy": val_acc, "fitzpatrick_accuracy": fitz_acc},
                best_ckpt,
            )
            logger.info("New best val accuracy %.4f at epoch %d", val_acc, epoch)

    # --- Final report ---
    logger.info("=" * 60)
    logger.info("Best val accuracy: %.4f (epoch %d)", best_val_acc, best_epoch)
    logger.info("Fitzpatrick-stratified accuracy at best epoch:")
    for ft in sorted(best_fitz_acc):
        logger.info("  Fitzpatrick %s : %.4f", ft, best_fitz_acc[ft])
    logger.info("Best checkpoint: %s", best_ckpt)

    if run is not None:
        run.summary.update(
            {"best_val_accuracy": best_val_acc, "best_epoch": best_epoch}
        )
        run.finish()


if __name__ == "__main__":
    main()
