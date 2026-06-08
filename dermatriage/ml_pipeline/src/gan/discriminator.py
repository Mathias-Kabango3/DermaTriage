"""Conditional WGAN-GP critic.

Scores a (224x224 image, condition) pair with a single unbounded real value.
The condition vector is tiled across the spatial dimensions and concatenated
to the image as extra channels.

Note: BatchNorm is used here per the project spec. WGAN-GP critics often
prefer LayerNorm/InstanceNorm because BatchNorm couples samples within a
batch, which interferes with the per-sample gradient penalty. Swap the norm
if gradient-penalty stability becomes an issue.
"""

import torch
import torch.nn as nn


def _critic_block(in_ch, out_ch, kernel_size=4, stride=2, padding=1):
    """Conv2d -> BatchNorm2d -> LeakyReLU(0.2) downsampling block."""
    return nn.Sequential(
        nn.Conv2d(in_ch, out_ch, kernel_size, stride, padding, bias=False),
        nn.BatchNorm2d(out_ch),
        nn.LeakyReLU(0.2, inplace=True),
    )


class ConditionalCritic(nn.Module):
    """Maps (image, condition) -> a scalar critic score.

    Spatial progression (4 downsampling blocks):
        224x224 -> 112x112 -> 56x56 -> 28x28 -> 14x14 -> AdaptiveAvgPool -> 1x1
    """

    def __init__(self, condition_dim=11):
        super().__init__()
        self.condition_dim = condition_dim

        in_ch = 3 + condition_dim  # image channels + tiled condition channels

        self.net = nn.Sequential(
            _critic_block(in_ch, 64),    # 224 -> 112
            _critic_block(64, 128),      # 112 -> 56
            _critic_block(128, 256),     # 56 -> 28
            _critic_block(256, 512),     # 28 -> 14
        )
        self.pool = nn.AdaptiveAvgPool2d(1)
        self.head = nn.Linear(512, 1)

    def forward(self, img, condition):
        """Score an image conditioned on a label vector.

        Args:
            img: Image tensor of shape (N, 3, H, W).
            condition: Condition tensor of shape (N, condition_dim).

        Returns:
            Tensor of shape (N, 1) — unbounded critic scores.
        """
        n, _, h, w = img.shape
        cond_map = condition.view(n, self.condition_dim, 1, 1).expand(-1, -1, h, w)
        x = torch.cat([img, cond_map], dim=1)
        x = self.net(x)
        x = self.pool(x).flatten(1)  # (N, 512)
        return self.head(x)
