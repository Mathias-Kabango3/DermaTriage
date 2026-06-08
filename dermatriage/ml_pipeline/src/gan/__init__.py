"""Conditional WGAN-GP for synthetic dark-skin image augmentation."""

from . import discriminator, generator, train_gan, wgan_gp
from .discriminator import ConditionalCritic
from .generator import ConditionalGenerator
from .train_gan import train_wgan_gp
from .wgan_gp import compute_gradient_penalty

__all__ = [
    "discriminator",
    "generator",
    "train_gan",
    "wgan_gp",
    "ConditionalCritic",
    "ConditionalGenerator",
    "train_wgan_gp",
    "compute_gradient_penalty",
]
