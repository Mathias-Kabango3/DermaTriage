import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/triage_result.dart';
import '../../services/inference/inference_service.dart';
import '../../services/retrieval/retrieval_service.dart';

/// Lifecycle of a single triage run.
enum TriageState { idle, processing, done, error }

/// Drives the capture → inference → result flow for the UI.
class TriageProvider extends ChangeNotifier {
  final InferenceService _inferenceService;
  final RetrievalService _retrievalService;

  TriageProvider({
    InferenceService? inferenceService,
    RetrievalService? retrievalService,
  })  : _inferenceService = inferenceService ?? InferenceService(),
        _retrievalService = retrievalService ?? RetrievalService();

  TriageState _state = TriageState.idle;
  TriageResult? _result;
  File? _capturedImage;
  String? _error;
  RetrievalResult? _retrieval;
  bool _retrievalLoading = false;

  TriageState get state => _state;
  TriageResult? get result => _result;
  File? get capturedImage => _capturedImage;
  String? get error => _error;

  /// Retrieved similar confirmed cases for the current result, or null before
  /// retrieval has run (or when it doesn't apply — see [_maybeRetrieve]).
  RetrievalResult? get retrieval => _retrieval;
  bool get retrievalLoading => _retrievalLoading;

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

    // Retrieval runs after the result is already shown — it must never delay
    // the triage outcome the CHW is waiting on.
    final TriageResult? result = _result;
    if (result != null) await _maybeRetrieve(result);
  }

  /// Retrieve similar confirmed cases for [result], when applicable.
  ///
  /// The reference bank only covers fungal/scabies/eczema (the three
  /// diagnosable classes), so retrieval only ever runs for
  /// [TriageOutcome.diagnosis]. `not_skin` and `healthy_skin` have no bank
  /// coverage at all — running retrieval for them would surface "similar"
  /// cases from unrelated disease classes, which is misleading rather than
  /// informative, so the UI shows a neutral message instead without ever
  /// calling this.
  Future<void> _maybeRetrieve(TriageResult result) async {
    final List<double>? embedding = result.embedding;
    if (!result.isDiagnosis || embedding == null) {
      _retrieval = null;
      return;
    }
    _retrievalLoading = true;
    notifyListeners();
    _retrieval = await _retrievalService.retrieve(embedding, k: 3);
    _retrievalLoading = false;
    notifyListeners();
  }

  /// Clear all triage state back to idle.
  void reset() {
    _state = TriageState.idle;
    _result = null;
    _capturedImage = null;
    _error = null;
    _retrieval = null;
    _retrievalLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _inferenceService.dispose();
    super.dispose();
  }
}
