"""MobileNetV3-Small student model (timm)."""

import timm

STUDENT_ARCH = "mobilenetv3_small_100"


def build_student(num_classes=12, pretrained=True):
    """Build the MobileNetV3-Small student with a fresh classifier head.

    Args:
        num_classes: Number of output classes.
        pretrained: Load ImageNet-pretrained backbone weights.

    Returns:
        torch.nn.Module: The student model.
    """
    return timm.create_model(
        STUDENT_ARCH,
        pretrained=pretrained,
        num_classes=num_classes,
    )


def get_student_target_layer(model):
    """Return the last convolutional layer for Grad-CAM.

    timm's MobileNetV3 exposes the final 1x1 conv as ``conv_head``; we fall
    back to the last block if that attribute is unavailable.
    """
    if hasattr(model, "conv_head"):
        return model.conv_head
    return model.blocks[-1]
