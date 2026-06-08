"""DataLoader construction for the DermaTriage training splits."""

from pathlib import Path

from torch.utils.data import DataLoader

from .dataset import SkinDataset


def build_dataloaders(cfg, batch_size=None, num_workers=4):
    """Build train/val/test DataLoaders from the processed manifests.

    Each split is read from
    ``cfg["data"]["processed_path"]/<split>/manifest.csv``.

    Args:
        cfg: Full pipeline config dict.
        batch_size: Override batch size. If ``None``, falls back to
            ``cfg["teacher"]["batch_size"]`` (distillation can pass its own).
        num_workers: Worker processes per loader.

    Returns:
        tuple: ``(train_loader, val_loader, test_loader)``.
    """
    data_cfg = cfg["data"]
    processed_root = Path(data_cfg["processed_path"])
    image_size = data_cfg["image_size"]
    if batch_size is None:
        batch_size = cfg["teacher"]["batch_size"]

    loaders = []
    for split in ("train", "val", "test"):
        manifest = processed_root / split / "manifest.csv"
        dataset = SkinDataset(manifest, image_size=image_size, split=split)
        loaders.append(
            DataLoader(
                dataset,
                batch_size=batch_size,
                shuffle=(split == "train"),
                num_workers=num_workers,
                pin_memory=True,
                drop_last=(split == "train"),
            )
        )

    return tuple(loaders)
