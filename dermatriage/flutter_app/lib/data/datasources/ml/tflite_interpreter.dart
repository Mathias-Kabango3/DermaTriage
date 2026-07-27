import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Raw outputs of one model run. [embedding] is null for a logits-only model
/// (e.g. the parity test's paired checkpoint).
class ModelOutputs {
  /// Raw class logits, length [AppConstants.numClasses].
  final List<double> logits;

  /// L2-normalised 576-d retrieval embedding, or null if this model has no
  /// embedding head.
  final List<double>? embedding;

  const ModelOutputs({required this.logits, required this.embedding});

  /// True when this run carries the retrieval embedding.
  bool get hasEmbedding => embedding != null;
}

/// Thin wrapper around the TFLite [Interpreter] for the skin-triage model.
///
/// Handles both the production model (logits + a 576-d retrieval embedding)
/// and a plain logits-only classifier (used by the parity test). Outputs are
/// resolved by tensor name at load time, never by hardcoded position — export
/// tooling does not guarantee output order.
class SkinTriageInterpreter {
  Interpreter? _interpreter;

  int _numClasses = AppConstants.numClasses;

  /// True when the model expects channels-first input `[1, 3, H, W]` (NCHW,
  /// PyTorch/ONNX layout) rather than channels-last `[1, H, W, 3]` (NHWC).
  bool _inputNchw = false;

  // Resolved output positions (indices into getOutputTensors()).
  int _logitsOut = 0;
  int _embOut = -1;
  int _embDim = 0;

  bool get isLoaded => _interpreter != null;

  /// Whether the loaded model exposes the retrieval embedding head.
  bool get hasEmbedding => _embOut >= 0;

  /// Most recent inference latency in milliseconds (for the model-info screen).
  int lastLatencyMs = 0;

  /// Load the bundled TFLite model from assets.
  ///
  /// Idempotent: a no-op once loaded. Rethrows any load/allocation failure so
  /// the caller can surface a meaningful message instead of a later null-check
  /// crash. Wraps the underlying error with the model path for context.
  ///
  /// [modelFile] overrides the bundled asset. It exists so parity tests can put
  /// a different checkpoint through this exact code path; production always
  /// uses the asset.
  Future<void> load({File? modelFile}) async {
    if (_interpreter != null) return;
    try {
      final Interpreter interpreter = modelFile != null
          ? Interpreter.fromFile(modelFile)
          : await Interpreter.fromAsset(AppConstants.modelAssetPath);
      _interpreter = interpreter;
      interpreter.allocateTensors();

      // Detect input layout: NCHW [1,3,H,W] (ONNX/PyTorch) vs NHWC [1,H,W,3].
      final List<int> inShape = interpreter.getInputTensor(0).shape;
      _inputNchw = inShape.length == 4 && inShape[1] == 3 && inShape[2] != 3;

      _resolveOutputs(interpreter);

      developer.log(
        'Loaded TFLite model from ${AppConstants.modelAssetPath} '
        '(input $inShape ${_inputNchw ? "NCHW" : "NHWC"}, '
        'logits@$_logitsOut embedding@$_embOut, hasEmbedding=$hasEmbedding)',
        name: 'SkinTriageInterpreter',
      );
    } catch (e, st) {
      developer.log(
        'Failed to load TFLite model from ${AppConstants.modelAssetPath}',
        name: 'SkinTriageInterpreter',
        error: e,
        stackTrace: st,
      );
      throw Exception(
        'Could not load the AI model (${AppConstants.modelAssetPath}): $e',
      );
    }
  }

  /// Identify the logits / embedding output tensors by name, with a
  /// single-output fallback for a plain classifier. Sets [_numClasses] from
  /// the logits head.
  void _resolveOutputs(Interpreter interpreter) {
    final List<Tensor> outs = interpreter.getOutputTensors();

    try {
      _logitsOut = interpreter.getOutputIndex('logits');
    } catch (_) {
      _logitsOut = 0; // Logits-only model with an unnamed output.
    }
    try {
      _embOut = interpreter.getOutputIndex('embedding');
      _embDim = outs[_embOut].shape.last;
    } catch (_) {
      _embOut = -1; // No retrieval head on this model.
      _embDim = 0;
    }
    _numClasses = outs[_logitsOut].shape.last;
  }

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is the NHWC `Float32List` from `ImageProcessor.preprocess`.
  ModelOutputs run(Float32List inputTensor) {
    final Interpreter? interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('AI model is not loaded.');
    }
    const int size = AppConstants.imageSize;

    // [inputTensor] is always NHWC (interleaved RGB). If the model wants NCHW,
    // transpose to planar channels-first before feeding it.
    final Object input;
    if (_inputNchw) {
      final Float32List chw = Float32List(3 * size * size);
      const int plane = size * size;
      for (int pix = 0; pix < plane; pix++) {
        final int hwc = pix * 3;
        chw[pix] = inputTensor[hwc]; // R plane
        chw[plane + pix] = inputTensor[hwc + 1]; // G plane
        chw[2 * plane + pix] = inputTensor[hwc + 2]; // B plane
      }
      input = chw.reshape(<int>[1, 3, size, size]);
    } else {
      input = inputTensor.reshape(<int>[1, size, size, 3]);
    }

    final List<dynamic> logitsNested =
        List<double>.filled(_numClasses, 0.0).reshape(<int>[1, _numClasses]);
    final Map<int, Object> outputMap = <int, Object>{_logitsOut: logitsNested};

    List<dynamic>? embNested;
    if (_embOut >= 0) {
      embNested =
          List<double>.filled(_embDim, 0.0).reshape(<int>[1, _embDim]);
      outputMap[_embOut] = embNested;
    }

    final stopwatch = Stopwatch()..start();
    interpreter.runForMultipleInputs(<Object>[input], outputMap);
    stopwatch.stop();
    lastLatencyMs = stopwatch.elapsedMilliseconds;
    developer.log(
      'Inference latency: $lastLatencyMs ms',
      name: 'SkinTriageInterpreter',
    );

    return ModelOutputs(
      logits: List<double>.from(logitsNested[0] as List),
      embedding: embNested != null
          ? _l2Normalise(List<double>.from(embNested[0] as List))
          : null,
    );
  }

  /// Back-compat convenience for callers that only need the logits.
  List<double> predict(Float32List inputTensor) => run(inputTensor).logits;

  /// The embedding head is the raw pooled backbone feature (arbitrary scale,
  /// not a unit vector) — normalise here so every caller can treat
  /// [ModelOutputs.embedding] as ready for cosine similarity via a plain dot
  /// product.
  static List<double> _l2Normalise(List<double> v) {
    double sumSq = 0.0;
    for (final double x in v) {
      sumSq += x * x;
    }
    final double norm = math.sqrt(sumSq);
    if (norm == 0) return v;
    return v.map((double x) => x / norm).toList();
  }

  /// Release native interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
