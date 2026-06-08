import 'dart:io';

import 'package:flutter/material.dart';

/// Overlays a Grad-CAM heatmap on the captured image.
///
/// When [heatmapPath] points to an existing file the heatmap is blended over
/// the base [image] at 50% opacity. Otherwise a subtle placeholder message is
/// shown (the placeholder model ships without explanations).
class GradCAMOverlay extends StatelessWidget {
  final Image image;
  final String? heatmapPath;

  const GradCAMOverlay({super.key, required this.image, this.heatmapPath});

  bool get _hasHeatmap =>
      heatmapPath != null && File(heatmapPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        image,
        if (_hasHeatmap)
          Opacity(
            opacity: 0.5,
            child: Image.file(File(heatmapPath!), fit: BoxFit.cover),
          )
        else
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              color: Colors.black.withValues(alpha: 0.45),
              child: const Text(
                'Explanation unavailable for placeholder model',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
