"""WGAN-GP gradient penalty."""

import torch
import torch.autograd as autograd


def compute_gradient_penalty(
    critic, real_imgs, fake_imgs, condition, device, lambda_gp=10.0
):
    """Compute the WGAN-GP gradient penalty term.

    Enforces the 1-Lipschitz constraint by penalising the deviation of the
    critic's input-gradient norm from 1, measured at points interpolated
    between real and fake samples.

    Args:
        critic: The conditional critic.
        real_imgs: Real image batch (N, C, H, W).
        fake_imgs: Generated image batch (N, C, H, W).
        condition: Condition vectors (N, condition_dim).
        device: Torch device.
        lambda_gp: Penalty coefficient.

    Returns:
        Scalar tensor: ``lambda_gp * E[(||grad||_2 - 1)^2]``.
    """
    batch_size = real_imgs.size(0)

    # Per-sample interpolation coefficient, broadcast over C, H, W.
    alpha = torch.rand(batch_size, 1, 1, 1, device=device)
    interpolates = alpha * real_imgs + (1.0 - alpha) * fake_imgs
    interpolates = interpolates.requires_grad_(True)

    critic_interpolates = critic(interpolates, condition)
    grad_outputs = torch.ones_like(critic_interpolates, device=device)

    gradients = autograd.grad(
        outputs=critic_interpolates,
        inputs=interpolates,
        grad_outputs=grad_outputs,
        create_graph=True,
        retain_graph=True,
        only_inputs=True,
    )[0]

    gradients = gradients.view(batch_size, -1)
    grad_norm = gradients.norm(2, dim=1)
    return lambda_gp * ((grad_norm - 1.0) ** 2).mean()
