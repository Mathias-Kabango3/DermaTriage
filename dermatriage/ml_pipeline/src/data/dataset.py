"""PyTorch Dataset for harmonised skin disease images."""

import pandas as pd
import torch
from PIL import Image
from torch.utils.data import Dataset
from torchvision import transforms

# ImageNet normalisation statistics (the teacher backbone is pretrained on it).
IMAGENET_MEAN = [0.485, 0.456, 0.406]
IMAGENET_STD = [0.229, 0.224, 0.225]


class SkinDataset(Dataset):
    """Reads a manifest CSV and serves transformed skin images.

    Expected CSV columns:
        image_path, label_idx, fitzpatrick_type, source, is_synthetic
    """

    def __init__(self, csv_path, image_size=224, split="train"):
        self.df = pd.read_csv(csv_path)
        self.image_size = image_size
        self.split = split
        self.transform = self._build_transform(image_size, split)

    @staticmethod
    def _build_transform(size, split):
        """Build the torchvision transform pipeline for a given split.

        Train applies stochastic augmentation; val/test are deterministic.
        """
        normalize = transforms.Normalize(mean=IMAGENET_MEAN, std=IMAGENET_STD)
        if split == "train":
            return transforms.Compose(
                [
                    transforms.RandomResizedCrop(size, scale=(0.8, 1.0)),
                    transforms.RandomHorizontalFlip(),
                    transforms.ColorJitter(
                        brightness=0.2, contrast=0.2, saturation=0.2, hue=0.02
                    ),
                    transforms.ToTensor(),
                    normalize,
                ]
            )
        return transforms.Compose(
            [
                transforms.Resize((size, size)),
                transforms.ToTensor(),
                normalize,
            ]
        )

    def __len__(self):
        return len(self.df)

    def __getitem__(self, idx):
        row = self.df.iloc[idx]
        image = Image.open(row["image_path"]).convert("RGB")
        image = self.transform(image)
        return {
            "image": image,
            "label": int(row["label_idx"]),
            "fitzpatrick": int(row["fitzpatrick_type"]),
            "is_synthetic": bool(row["is_synthetic"]),
        }
