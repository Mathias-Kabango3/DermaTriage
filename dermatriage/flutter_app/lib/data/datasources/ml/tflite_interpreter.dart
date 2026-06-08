import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';

/// Thin wrapper around the TFLite [Interpreter] for the skin-triage model.
class SkinTriageInterpreter {
  Interpreter? _interpreter;

  bool get isLoaded => _interpreter != null;

  /// Load the bundled TFLite model from assets.
  Future<void> load() async {
    _interpreter = await Interpreter.fromAsset(AppConstants.modelAssetPath);
    developer.log(
      'Loaded TFLite model from ${AppConstants.modelAssetPath}',
      name: 'SkinTriageInterpreter',
    );
  }

  /// Run inference on a preprocessed input tensor.
  ///
  /// [inputTensor] is the NHWC `Float32List` from `ImageProcessor.preprocess`.
  /// Returns the model's raw output as a `List<double>` of length
  /// [AppConstants.numClasses].
  List<double> predict(Float32List inputTensor) {
    final Interpreter interpreter = _interpreter!;
    const int size = AppConstants.imageSize;
    const int numClasses = AppConstants.numClasses;

    final input = inputTensor.reshape(<int>[1, size, size, 3]);
    final output = List.filled(1 * numClasses, 0.0).reshape(<int>[1, numClasses]);

    final stopwatch = Stopwatch()..start();
    interpreter.run(input, output);
    stopwatch.stop();
    developer.log(
      'Inference latency: ${stopwatch.elapsedMilliseconds} ms',
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
