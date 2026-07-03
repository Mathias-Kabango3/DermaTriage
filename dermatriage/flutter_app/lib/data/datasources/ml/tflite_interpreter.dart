import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Thin wrapper around the TFLite [Interpreter] for the skin-triage model.
class SkinTriageInterpreter {
  Interpreter? _interpreter;

  /// Number of output classes, read from the loaded model's output tensor so
  /// the buffer always matches the model (falls back to the configured count).
  int _numClasses = AppConstants.numClasses;

  /// True when the model expects channels-first input `[1, 3, H, W]` (NCHW,
  /// PyTorch/ONNX layout) rather than channels-last `[1, H, W, 3]` (NHWC).
  bool _inputNchw = false;

  bool get isLoaded => _interpreter != null;

  /// Most recent inference latency in milliseconds (for the model-info screen).
  int lastLatencyMs = 0;

  /// Load the bundled TFLite model from assets.
  ///
  /// Idempotent: a no-op once loaded. Rethrows any load/allocation failure so
  /// the caller can surface a meaningful message instead of a later null-check
  /// crash. Wraps the underlying error with the model path for context.
  Future<void> load() async {
    if (_interpreter != null) return;
    try {
      final Interpreter interpreter =
          await Interpreter.fromAsset(AppConstants.modelAssetPath);
      _interpreter = interpreter;
      interpreter.allocateTensors();

      // Detect input layout: NCHW [1,3,H,W] (ONNX/PyTorch) vs NHWC [1,H,W,3].
      final List<int> inShape = interpreter.getInputTensor(0).shape;
      _inputNchw =
          inShape.length == 4 && inShape[1] == 3 && inShape[2] != 3;

      // Size the output buffer from the model itself (last output dim).
      final List<int> outShape = interpreter.getOutputTensor(0).shape;
      if (outShape.isNotEmpty && outShape.last > 0) {
        _numClasses = outShape.last;
      }
      developer.log(
        'Loaded TFLite model from ${AppConstants.modelAssetPath} '
        '(input $inShape, ${_inputNchw ? "NCHW" : "NHWC"}, output $outShape)',
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

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is the NHWC `Float32List` from `ImageProcessor.preprocess`.
  /// Returns the model's raw logits as a `List<double>`.
  List<double> predict(Float32List inputTensor) {
    final Interpreter? interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('AI model is not loaded.');
    }
    const int size = AppConstants.imageSize;
    final int numClasses = _numClasses;

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
    final output = List.filled(1 * numClasses, 0.0).reshape(<int>[1, numClasses]);

    final stopwatch = Stopwatch()..start();
    interpreter.run(input, output);
    stopwatch.stop();
    lastLatencyMs = stopwatch.elapsedMilliseconds;
    developer.log(
      'Inference latency: $lastLatencyMs ms',
      name: 'SkinTriageInterpreter',
    );

    return List<double>.from(output[0] as List);
  }

  /// Release native interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
