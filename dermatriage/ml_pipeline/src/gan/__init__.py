"""Conditional WGAN-GP for synthetic dark-skin image augmentation."""

from . import discriminator, generator
from .discriminator import ConditionalCritic
from .generator import ConditionalGenerator

__all__ = [
    "discriminator",
    "generator",
    "ConditionalCritic",
    "ConditionalGenerator",
]
