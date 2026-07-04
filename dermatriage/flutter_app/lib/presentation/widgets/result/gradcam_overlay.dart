import 'dart:io';

import 'package:flutter/material.dart';

/// Overlays a "region of interest" heatmap on the captured image.
///
/// The heatmap is an occlusion-based saliency approximation (not literal
/// Grad-CAM): it highlights the area that, when hidden, most changes the
/// model's decision. When [heatmapPath] points to an existing file it is
/// blended over the base [image]; while [isLoading] is true a small spinner is
/// shown instead.
class GradCAMOverlay extends StatelessWidget {
  final Image image;
  final String? heatmapPath;
  final bool isLoading;

  const GradCAMOverlay({
    super.key,
    required this.image,
    this.heatmapPath,
    this.isLoading = false,
  });

  bool get _hasHeatmap =>
      heatmapPath != null && File(heatmapPath!).existsSync();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        image,
        if (_hasHeatmap) ...<Widget>[
          Opacity(
            opacity: 0.5,
            child: Image.file(File(heatmapPath!), fit: BoxFit.cover),
          ),
          _caption('Region of interest (approximate)'),
        ] else if (isLoading)
          _caption('Finding region of interest…', showSpinner: true),
      ],
    );
  }

  /// A small translucent caption pinned to the bottom of the image.
  Widget _caption(String text, {bool showSpinner = false}) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        color: Colors.black.withValues(alpha: 0.45),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (showSpinner) ...<Widget>[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
