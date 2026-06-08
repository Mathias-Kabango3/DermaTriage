"""Inference-friendly wrapper around the MobileNetV3 student."""

import torch
import torch.nn as nn
import torch.nn.functional as F


class StudentModelWrapper(nn.Module):
    """Wraps the student model with a convenience inference API.

    ``forward`` returns raw logits (so the wrapper drops into training and
    distillation loops unchanged); ``infer`` adds a no-grad, eval-mode
    convenience path for single predictions.
    """

    def __init__(self, student):
        super().__init__()
        self.student = student

    def forward(self, x):
        """Return raw class logits."""
        return self.student(x)

    @torch.no_grad()
    def infer(self, tensor):
        """Run eval-mode inference on a single batch without tracking grads.

        Args:
            tensor: Input image tensor of shape (N, C, H, W) or (C, H, W).

        Returns:
            tuple: ``(predicted_class_idx, confidence, all_probs)`` for the
            first sample, where ``all_probs`` is the full probability vector.
        """
        was_training = self.training
        self.eval()

        if tensor.dim() == 3:
            tensor = tensor.unsqueeze(0)

        logits = self.forward(tensor)
        probs = F.softmax(logits, dim=1)
        confidence, predicted = torch.max(probs, dim=1)

        if was_training:
            self.train()

        return (
            int(predicted[0].item()),
            float(confidence[0].item()),
            probs[0].detach().cpu(),
        )
