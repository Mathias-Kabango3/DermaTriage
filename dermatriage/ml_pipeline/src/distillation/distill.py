"""Knowledge distillation: EfficientNet-B4 teacher -> MobileNetV3 student."""

from pathlib import Path

import torch
import torch.nn.functional as F
from torch.optim.lr_scheduler import CosineAnnealingLR

from ..data.dataloader import build_dataloaders
from ..models.student import build_student
from ..models.teacher import build_teacher
from ..utils.checkpoint import load_checkpoint, save_checkpoint
from ..utils.logger import get_logger
from .loss import DistillationLoss

logger = get_logger(__name__)


def _load_teacher(cfg, device):
    """Build the teacher and load its best checkpoint, frozen for eval."""
    teacher = build_teacher(
        num_classes=cfg["data"]["num_classes"],
        pretrained=False,  # weights come from the checkpoint
    ).to(device)

    ckpt_dir = Path(cfg["teacher"].get("checkpoint_dir", "models/teacher"))
    ckpt_path = ckpt_dir / "teacher_best.pt"
    epoch, metrics = load_checkpoint(teacher, None, ckpt_path, device)
    logger.info(
        "Loaded teacher from %s (epoch %s, val_acc %s)",
        ckpt_path, epoch, metrics.get("val_accuracy"),
    )

    teacher.eval()
    for p in teacher.parameters():
        p.requires_grad = False
    return teacher


@torch.no_grad()
def validate_real_only(student, loader, device):
    """Validate the student on real images only.

    Synthetic samples (``is_synthetic == True``) are excluded so reported
    metrics reflect performance on genuine data.

    Returns:
        tuple: ``(avg_loss, accuracy, fitzpatrick_accuracies)``.
    """
    student.eval()

    running_loss = 0.0
    correct = 0
    total = 0
    fitz_correct = {}
    fitz_total = {}

    for batch in loader:
        real_mask = ~batch["is_synthetic"]
        if real_mask.sum().item() == 0:
            continue

        images = batch["image"][real_mask].to(device, non_blocking=True)
        labels = batch["label"][real_mask].to(device, non_blocking=True)
        fitz = batch["fitzpatrick"][real_mask]

        logits = student(images)
        loss = F.cross_entropy(logits, labels)

        preds = logits.argmax(dim=1)
        running_loss += loss.item() * labels.size(0)
        correct += (preds == labels).sum().item()
        total += labels.size(0)

        correct_mask = (preds == labels).cpu()
        for ft, is_correct in zip(fitz.tolist(), correct_mask.tolist()):
            fitz_total[ft] = fitz_total.get(ft, 0) + 1
            fitz_correct[ft] = fitz_correct.get(ft, 0) + int(is_correct)

    fitz_acc = {ft: fitz_correct[ft] / fitz_total[ft] for ft in sorted(fitz_total)}
    return running_loss / max(total, 1), correct / max(total, 1), fitz_acc


def distill_student(cfg, device, run=None):
    """Distill the teacher into a MobileNetV3-Small student.

    Args:
        cfg: Full pipeline config dict.
        device: Torch device.
        run: Optional active wandb run for logging.

    Returns:
        dict: ``{"best_val_accuracy", "best_epoch", "best_checkpoint"}``.
    """
    distill_cfg = cfg["distillation"]
    epochs = distill_cfg["epochs"]

    # --- Data (train may include synthetic; val is filtered to real only) ---
    train_loader, val_loader, _ = build_dataloaders(
        cfg, batch_size=distill_cfg["batch_size"]
    )

    # --- Models ---
    teacher = _load_teacher(cfg, device)
    student = build_student(
        num_classes=cfg["data"]["num_classes"], pretrained=True
    ).to(device)

    # --- Loss / optim / schedule ---
    criterion = DistillationLoss(
        temperature=distill_cfg["temperature"], alpha=distill_cfg["alpha"]
    )
    optimizer = torch.optim.AdamW(student.parameters(), lr=distill_cfg["lr"])
    scheduler = CosineAnnealingLR(optimizer, T_max=max(epochs, 1))

    ckpt_dir = Path(distill_cfg.get("checkpoint_dir", "models/student"))
    best_ckpt = ckpt_dir / "student_best.pt"
    best_val_acc = 0.0
    best_epoch = -1
    best_fitz_acc = {}

    for epoch in range(1, epochs + 1):
        student.train()
        running_loss = 0.0
        total = 0

        for batch in train_loader:
            images = batch["image"].to(device, non_blocking=True)
            labels = batch["label"].to(device, non_blocking=True)

            with torch.no_grad():
                teacher_logits = teacher(images)
            student_logits = student(images)
            loss = criterion(student_logits, teacher_logits, labels)

            optimizer.zero_grad(set_to_none=True)
            loss.backward()
            optimizer.step()

            running_loss += loss.item() * labels.size(0)
            total += labels.size(0)

        scheduler.step()
        train_loss = running_loss / max(total, 1)
        val_loss, val_acc, fitz_acc = validate_real_only(student, val_loader, device)

        logger.info(
            "Epoch %d/%d | distill loss %.4f | val loss %.4f acc %.4f",
            epoch, epochs, train_loss, val_loss, val_acc,
        )

        metrics = {
            "distill/loss": train_loss,
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
                student, optimizer, epoch,
                {"val_accuracy": val_acc, "fitzpatrick_accuracy": fitz_acc},
                best_ckpt,
            )
            logger.info("New best student val accuracy %.4f at epoch %d",
                        val_acc, epoch)

    logger.info("=" * 60)
    logger.info("Best student val accuracy: %.4f (epoch %d)",
                best_val_acc, best_epoch)
    logger.info("Fitzpatrick-stratified accuracy at best epoch:")
    for ft in sorted(best_fitz_acc):
        logger.info("  Fitzpatrick %s : %.4f", ft, best_fitz_acc[ft])

    return {
        "best_val_accuracy": best_val_acc,
        "best_epoch": best_epoch,
        "best_checkpoint": str(best_ckpt),
    }
