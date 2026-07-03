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
  bool _heatmapLoading = false;

  TriageState get state => _state;
  TriageResult? get result => _result;
  File? get capturedImage => _capturedImage;
  String? get error => _error;

  /// True while the "region of interest" heatmap is being computed in the
  /// background, after a diagnosis has already been shown.
  bool get heatmapLoading => _heatmapLoading;

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
      notifyListeners();
      // Show the diagnosis immediately, then compute the explanation heatmap in
      // the background. Rejection outcomes get no heatmap.
      await _generateHeatmap(image);
      return;
    } catch (e) {
      _error = e.toString();
      _state = TriageState.error;
    }
    notifyListeners();
  }

  /// Best-effort: generate the region-of-interest heatmap for a diagnosis and
  /// attach it to the current result. Never throws into the UI.
  Future<void> _generateHeatmap(File image) async {
    final TriageResult? result = _result;
    if (result == null || !result.isDiagnosis) return;

    _heatmapLoading = true;
    notifyListeners();

    final String? path = await _inferenceService.generateSaliencyMap(
      image,
      result.predictedClassIndex,
    );

    // The run may have been reset while we were computing.
    if (_result != result) return;
    if (path != null) _result = result.copyWith(heatmapPath: path);
    _heatmapLoading = false;
    notifyListeners();
  }

  /// Clear all triage state back to idle.
  void reset() {
    _state = TriageState.idle;
    _result = null;
    _capturedImage = null;
    _error = null;
    _heatmapLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }
}
