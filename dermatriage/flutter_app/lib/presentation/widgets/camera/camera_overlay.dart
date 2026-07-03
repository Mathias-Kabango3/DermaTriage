import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A dark scrim with a clear rounded-rectangle cutout marking the lesion
/// target zone, plus guidance text below it.
class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // A large centred square matching the region the model analyses
        // (the centre crop of the captured photo).
        final double cutoutSize = math.min(
          constraints.maxWidth * 0.88,
          constraints.maxHeight * 0.6,
        );
        final Rect cutout = Rect.fromCenter(
          center: Offset(
            constraints.maxWidth / 2,
            constraints.maxHeight * 0.4,
          ),
          width: cutoutSize,
          height: cutoutSize,
        );

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
              child: const Text(
                'Centre the lesion in the box and fill it',
                textAlign: TextAlign.center,
                style: TextStyle(
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
