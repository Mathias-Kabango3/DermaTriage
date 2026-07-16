import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/triage_result.dart';
import '../../services/inference/inference_service.dart';

/// Lifecycle of a single triage run.
enum TriageState { idle, processing, done, error }

/// Drives the capture → inference → result flow for the UI.
class TriageProvider extends ChangeNotifier {
  final InferenceService _inferenceService;

  TriageProvider({InferenceService? inferenceService})
      : _inferenceService = inferenceService ?? InferenceService();

  TriageState _state = TriageState.idle;
  TriageResult? _result;
  File? _capturedImage;
  String? _error;

  TriageState get state => _state;
  TriageResult? get result => _result;
  File? get capturedImage => _capturedImage;
  String? get error => _error;

  /// Load the on-device model. Safe to call once at startup.
  ///
  /// A failure here is swallowed deliberately: [runTriage] re-attempts the load
  /// and surfaces the real error to the result screen, so startup never crashes.
  Future<void> init() async {
    try {
      await _inferenceService.init();
    } catch (e) {
      debugPrint('Model preload failed (will retry on first triage): $e');
    }
  }

  /// Store a freshly captured image and clear any previous result.
  void setCapturedImage(File image) {
    _capturedImage = image;
    _result = null;
    _error = null;
    _state = TriageState.idle;
    notifyListeners();
  }

  /// Run inference on the captured image.
  Future<void> runTriage() async {
    final File? image = _capturedImage;
    if (image == null) {
      _error = 'No image captured.';
      _state = TriageState.error;
      notifyListeners();
      return;
    }

    _state = TriageState.processing;
    _error = null;
    notifyListeners();

    try {
      _result = await _inferenceService.runTriage(image);
      _state = TriageState.done;
    } catch (e) {
      _error = e.toString();
      _state = TriageState.error;
    }
    notifyListeners();
  }

  /// Clear all triage state back to idle.
  void reset() {
    _state = TriageState.idle;
    _result = null;
    _capturedImage = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }
}
