import 'dart:io';

import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/body_regions.dart';
import '../../../core/theme/colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/contribution_provider.dart';
import '../../widgets/camera/camera_overlay.dart';
import '../../widgets/camera/capture_button.dart';

/// Camera capture for the healthy-skin contribution flow. Deliberately a
/// separate widget/file from [CameraScreen] — same underlying `camera`
/// package plumbing, but its own state, so nothing here can regress the
/// tested triage capture path.
///
/// Metadata (Fitzpatrick type + body region) is already chosen on the
/// previous screen and passed in directly, matching how
/// [ContributionMetadataScreen] hands off — see that file's docstring for why
/// this isn't wired through named go_router routes.
class ContributionCameraScreen extends StatefulWidget {
  final int fitzpatrickType;
  final BodyRegion bodyRegion;

  const ContributionCameraScreen({
    super.key,
    required this.fitzpatrickType,
    required this.bodyRegion,
  });

  @override
  State<ContributionCameraScreen> createState() =>
      _ContributionCameraScreenState();
}

class _ContributionCameraScreenState extends State<ContributionCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  String? _unavailableReason;
  bool _permissionIssue = false;
  bool _flashOn = false;
  bool _capturing = false;

  void _setUnavailable(String reason, {required bool permission}) {
    if (mounted) {
      setState(() {
        _unavailableReason = reason;
        _permissionIssue = permission;
      });
    }
  }

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
    if (!mounted) return;
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!status.isGranted) {
      _setUnavailable(l10n.cameraPermission, permission: true);
      return;
    }
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      _setUnavailable(l10n.noCamera, permission: false);
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
      if (mounted) {
        _setUnavailable(AppLocalizations.of(context).cameraStartFailed,
            permission: false);
      }
      return;
    }
    if (mounted) setState(() => _unavailableReason = null);
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
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    try {
      final XFile shot = await controller.takePicture();
      final Directory dir = await getApplicationDocumentsDirectory();
      final String fileName =
          'contribution_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String savedPath = p.join(dir.path, fileName);
      await shot.saveTo(savedPath);
      if (!mounted) return;

      final String? uid = AuthProvider.instance.user?.uid;
      if (uid == null) {
        // The router already gates every screen behind login, so this is
        // defensive only — it should never actually happen.
        throw StateError('No signed-in CHW to attribute this contribution to.');
      }
      String facility = '';
      try {
        final profile = await AuthProvider.instance.service.loadProfile();
        facility = (profile['facility'] as String?) ?? '';
      } catch (_) {
        // Offline with nothing cached yet — submit with facility blank rather
        // than block the capture; it's optional metadata, not a blocker.
      }
      if (!mounted) return;

      await context.read<ContributionProvider>().submit(
            localPhotoPath: savedPath,
            fitzpatrickType: widget.fitzpatrickType,
            bodyRegion: widget.bodyRegion,
            contributorId: uid,
            facility: facility,
          );
      if (!mounted) return;

      final List<ConnectivityResult> connectivity =
          await Connectivity().checkConnectivity();
      final bool isOnline = !connectivity.contains(ConnectivityResult.none);
      if (!mounted) return;

      final AppLocalizations l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: Text(l10n.contributionSavedTitle),
          content: Text(
            isOnline
                ? l10n.contributionSavedMessageOnline
                : l10n.contributionSavedMessageOffline,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );
      if (!mounted) return;
      // Back to the metadata screen and then Home — done contributing for now.
      Navigator.of(context)
        ..pop()
        ..pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).captureFailed('$e'))),
        );
        setState(() => _capturing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unavailableReason != null) {
      return _CameraUnavailableView(
        message: _unavailableReason!,
        showSettings: _permissionIssue,
        onRetry: _setup,
        onBack: () => Navigator.of(context).pop(),
      );
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
          _FullScreenPreview(controller: controller),
          CameraOverlay(
            guidanceText: AppLocalizations.of(context).contributionCameraGuidance,
            fullFrame: true,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
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
            colors: <Color>[
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: Row(
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
            CaptureButton(enabled: !_capturing, onPressed: _capture),
            IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
              onPressed: _cameras.length < 2 ? null : _switchCamera,
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenPreview extends StatelessWidget {
  final CameraController controller;

  const _FullScreenPreview({required this.controller});

  @override
  Widget build(BuildContext context) {
    final Size? preview = controller.value.previewSize;
    if (preview == null) return CameraPreview(controller);
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

class _CameraUnavailableView extends StatelessWidget {
  final String message;
  final bool showSettings;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _CameraUnavailableView({
    required this.message,
    required this.showSettings,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cameraTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.no_photography, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: Text(l10n.tryAgain)),
            if (showSettings) ...<Widget>[
              const SizedBox(height: 12),
              TextButton(onPressed: openAppSettings, child: Text(l10n.openAppSettings)),
            ],
            const SizedBox(height: 12),
            TextButton(onPressed: onBack, child: Text(l10n.goBack)),
          ],
        ),
      ),
    );
  }
}
