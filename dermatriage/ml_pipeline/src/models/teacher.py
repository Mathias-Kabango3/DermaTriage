"""EfficientNet-B4 teacher model (timm)."""

import timm

TEACHER_ARCH = "efficientnet_b4"


def build_teacher(num_classes=12, pretrained=True):
    """Build the EfficientNet-B4 teacher with a fresh classifier head.

    Args:
        num_classes: Number of output classes.
        pretrained: Load ImageNet-pretrained backbone weights.

    Returns:
        torch.nn.Module: The teacher model.
    """
    return timm.create_model(
        TEACHER_ARCH,
        pretrained=pretrained,
        num_classes=num_classes,
    )


def freeze_backbone(model, unfreeze_last_n_blocks=3):
    """Freeze the backbone, then unfreeze the last N blocks and the head.

    Used for staged fine-tuning: most of the pretrained backbone stays frozen
    while the deepest blocks and the classifier adapt to the skin domain.

    Args:
        model: Teacher model from :func:`build_teacher`.
        unfreeze_last_n_blocks: Number of trailing blocks to unfreeze.

    Returns:
        The same model, modified in place.
    """
    # Freeze everything first.
    for param in model.parameters():
        param.requires_grad = False

    # Unfreeze the last N blocks (timm EfficientNet exposes `.blocks`).
    for block in model.blocks[-unfreeze_last_n_blocks:]:
        for param in block.parameters():
            param.requires_grad = True

    # Unfreeze the final conv head / norm that feed the classifier.
    for attr in ("conv_head", "bn2"):
        module = getattr(model, attr, None)
        if module is not None:
            for param in module.parameters():
                param.requires_grad = True

    # Unfreeze the classifier head.
    for param in model.get_classifier().parameters():
        param.requires_grad = True

    return model


def get_teacher_target_layer(model):
    """Return the final spatial conv layer for Grad-CAM.

    timm's EfficientNet does not expose a torchvision-style ``.features``;
    the equivalent final feature map is produced by ``conv_head`` (falling
    back to the last block if that attribute is unavailable).
    """
    if hasattr(model, "conv_head"):
        return model.conv_head
    return model.blocks[-1]
