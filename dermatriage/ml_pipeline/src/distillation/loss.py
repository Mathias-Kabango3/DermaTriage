"""Knowledge-distillation loss (soft KL + hard CE)."""

import torch.nn as nn
import torch.nn.functional as F


class DistillationLoss(nn.Module):
    """Combined hard-label CE and soft-target KL distillation loss.

        L = alpha * CE(student, labels)
            + (1 - alpha) * T^2 * KL( softmax(student/T) || softmax(teacher/T) )

    The ``T^2`` factor restores the gradient magnitude scaled down by the
    softened temperature, as in Hinton et al. (2015).
    """

    def __init__(self, temperature=4.0, alpha=0.3):
        super().__init__()
        self.temperature = temperature
        self.alpha = alpha
        self.ce = nn.CrossEntropyLoss(label_smoothing=0.05)

    def forward(self, student_logits, teacher_logits, labels):
        T = self.temperature

        # Hard-label cross-entropy on the student's true logits.
        hard_loss = self.ce(student_logits, labels)

        # Soft-target KL divergence between temperature-softened distributions.
        student_log_probs = F.log_softmax(student_logits / T, dim=1)
        teacher_probs = F.softmax(teacher_logits / T, dim=1)
        soft_loss = F.kl_div(
            student_log_probs, teacher_probs, reduction="batchmean"
        ) * (T * T)

        return self.alpha * hard_loss + (1.0 - self.alpha) * soft_loss
