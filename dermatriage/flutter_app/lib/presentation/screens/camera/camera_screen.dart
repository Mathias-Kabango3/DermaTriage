import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../providers/triage_provider.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/capture_button.dart';
import '../../widgets/camera/fitzpatrick_selector.dart';

/// Live camera capture screen for photographing a skin lesion.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  bool _permissionDenied = false;
  bool _flashOn = false;
  bool _capturing = false;
  int? _fitzType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _setup() async {
    final PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _initController(CameraDescription camera) async {
    final CameraController controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
    } on CameraException {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleFlash() async {
    final CameraController? controller = _controller;
    if (controller == null) return;
    final bool next = !_flashOn;
    await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
    if (mounted) setState(() => _flashOn = next);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    _flashOn = false;
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> _capture() async {
    final CameraController? controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final XFile shot = await controller.takePicture();
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = p.join(dir.path, fileName);
      await shot.saveTo(savedPath);

      if (!mounted) return;
      context.read<TriageProvider>().setCapturedImage(File(savedPath));
      context.go('/result');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return _PermissionDeniedView(onRetry: _setup);
    }

    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          CameraPreview(controller),
          const CameraOverlay(),
          // Back button.
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.go('/patient/register'),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.only(top: 16, bottom: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Colors.transparent, Colors.black.withValues(alpha: 0.6)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'Confirm skin type',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            FitzpatrickSelector(
              selectedType: _fitzType,
              onSelected: (int t) => setState(() => _fitzType = t),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                IconButton(
                  icon: Icon(
                    _flashOn ? Icons.flash_on : Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _toggleFlash,
                ),
                CaptureButton(
                  enabled: !_capturing,
                  onPressed: _capture,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.cameraswitch,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: _cameras.length < 2 ? null : _switchCamera,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when camera permission is unavailable.
class _PermissionDeniedView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PermissionDeniedView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.no_photography,
                size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text(
              'Camera permission is required to capture a lesion photo.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Grant Permission'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: openAppSettings,
              child: const Text('Open App Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
