"""Conditional WGAN-GP generator.

Generates 224x224 RGB skin images conditioned on a one-hot vector encoding
the Fitzpatrick skin type (3 classes: types 4/5/6) and disease (8 classes).
"""

import torch
import torch.nn as nn


def _gen_block(in_ch, out_ch, kernel_size, stride, padding):
    """ConvTranspose2d -> BatchNorm2d -> ReLU upsampling block."""
    return nn.Sequential(
        nn.ConvTranspose2d(
            in_ch, out_ch, kernel_size, stride, padding, bias=False
        ),
        nn.BatchNorm2d(out_ch),
        nn.ReLU(inplace=True),
    )


class ConditionalGenerator(nn.Module):
    """Maps (noise, condition) -> a 224x224 RGB image.

    Spatial progression (4 upsampling blocks + Tanh output layer):
        1x1 -> 14x14 -> 28x28 -> 56x56 -> 112x112 -> 224x224
    """

    def __init__(self, z_dim=100, condition_dim=11, img_size=224):
        super().__init__()
        self.z_dim = z_dim
        self.condition_dim = condition_dim
        self.img_size = img_size

        in_ch = z_dim + condition_dim  # concatenated latent + condition

        self.net = nn.Sequential(
            # 1x1 -> 14x14
            _gen_block(in_ch, 512, kernel_size=14, stride=1, padding=0),
            # 14x14 -> 28x28
            _gen_block(512, 256, kernel_size=4, stride=2, padding=1),
            # 28x28 -> 56x56
            _gen_block(256, 128, kernel_size=4, stride=2, padding=1),
            # 56x56 -> 112x112
            _gen_block(128, 64, kernel_size=4, stride=2, padding=1),
            # 112x112 -> 224x224 (output layer, Tanh, no BN)
            nn.ConvTranspose2d(64, 3, kernel_size=4, stride=2, padding=1),
            nn.Tanh(),
        )

    def forward(self, z, condition):
        """Generate images from noise and a condition vector.

        Args:
            z: Noise tensor of shape (N, z_dim).
            condition: Condition tensor of shape (N, condition_dim).

        Returns:
            Tensor of shape (N, 3, img_size, img_size) in [-1, 1].
        """
        x = torch.cat([z, condition], dim=1)
        x = x.unsqueeze(-1).unsqueeze(-1)  # (N, in_ch, 1, 1)
        return self.net(x)
