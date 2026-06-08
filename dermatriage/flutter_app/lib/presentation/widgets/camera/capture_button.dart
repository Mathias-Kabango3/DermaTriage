import 'package:flutter/material.dart';

/// Large circular shutter button that scales down briefly when tapped.
class CaptureButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool enabled;

  const CaptureButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  State<CaptureButton> createState() => _CaptureButtonState();
}

class _CaptureButtonState extends State<CaptureButton> {
  double _scale = 1.0;

  void _setScale(double value) {
    if (!widget.enabled) return;
    setState(() => _scale = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(0.88),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: widget.enabled ? 0.3 : 0.15),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.enabled ? Colors.white : Colors.white54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
