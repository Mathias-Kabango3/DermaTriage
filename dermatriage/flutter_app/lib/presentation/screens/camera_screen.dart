import 'package:flutter/material.dart';

/// Placeholder camera capture screen — replace with the real camera UI.
class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Image')),
      body: const Center(child: Text('Camera')),
    );
  }
}
