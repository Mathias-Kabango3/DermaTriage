import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A dark scrim with a clear rounded-rectangle cutout marking the capture
/// target zone, plus guidance text below it.
class CameraOverlay extends StatelessWidget {
  /// Guidance text shown below the cutout. Defaults to the triage-capture
  /// wording; the contribution capture flow overrides it (no "lesion").
  final String guidanceText;

  /// Both the triage and contribution capture screens currently pass
  /// `true` — the model does a direct squash-resize to 224x224 with no
  /// centre-crop (see `ImageProcessor.preprocess`), so there's no technical
  /// reason the guide has to be a small square. The tight-square layout
  /// (`false`, the default) is kept available rather than deleted, in case
  /// a tighter close-up guide is wanted again for either screen later.
  final bool fullFrame;

  const CameraOverlay({
    super.key,
    this.guidanceText = 'Centre the lesion in the box and fill it',
    this.fullFrame = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Rect cutout;
        if (fullFrame) {
          // Nearly the entire viewfinder — just enough margin to keep the
          // white border on-screen and leave room for the guidance text.
          cutout = Rect.fromLTWH(
            constraints.maxWidth * 0.03,
            constraints.maxHeight * 0.04,
            constraints.maxWidth * 0.94,
            constraints.maxHeight * 0.78,
          );
        } else {
          // A large centred square — a tighter, close-up framing guide.
          final double cutoutSize = math.min(
            constraints.maxWidth * 0.88,
            constraints.maxHeight * 0.6,
          );
          cutout = Rect.fromCenter(
            center: Offset(
              constraints.maxWidth / 2,
              constraints.maxHeight * 0.4,
            ),
            width: cutoutSize,
            height: cutoutSize,
          );
        }

        return Stack(
          children: <Widget>[
            // Dark scrim with the cutout punched out.
            Positioned.fill(
              child: CustomPaint(
                painter: _ScrimPainter(cutout: cutout, radius: 20),
              ),
            ),
            // Guidance text just below the cutout.
            Positioned(
              top: cutout.bottom + 16,
              left: 24,
              right: 24,
              child: Text(
                guidanceText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect cutout;
  final double radius;

  _ScrimPainter({required this.cutout, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect =
        RRect.fromRectAndRadius(cutout, Radius.circular(radius));

    // Scrim everywhere except the cutout (even-odd fill rule).
    final Path scrim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(rrect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.6));

    // Bright border around the target zone.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) =>
      oldDelegate.cutout != cutout || oldDelegate.radius != radius;
}
