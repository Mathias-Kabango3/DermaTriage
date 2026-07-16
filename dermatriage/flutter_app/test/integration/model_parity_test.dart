// Runs the Flutter app's real on-device inference pipeline over a fixed set of
// test images and writes the results to JSON, so the Python side can compare
// them against PyTorch on the same inputs.
//
// This is deliberately the production code path — ImageProcessor.preprocess,
// SkinTriageInterpreter and DiseaseClassMapper — not a reimplementation. The
// integration risk being tested is exactly that the Dart preprocessing / tensor
// layout / class mapping drift from what the model was trained on.
//
// Two comparisons are exported:
//
//  1. `images`     — full pipeline from JPEG bytes, using the model bundled in
//                    the app's assets. Dart and Python resize with different
//                    algorithms, so logits differ slightly; the prediction must
//                    not.
//  2. `fixedTensor`— a deterministic tensor fed straight to the interpreter,
//                    bypassing image decoding. This isolates the engine and
//                    must match PyTorch to float32 noise.
//
// Run from flutter_app/:  flutter test test/integration/model_parity_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dermatriage/core/constants/disease_classes.dart';
import 'package:dermatriage/data/datasources/ml/disease_class_mapper.dart';
import 'package:dermatriage/data/datasources/ml/image_processor.dart';
import 'package:dermatriage/data/datasources/ml/tflite_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo-relative paths (tests run with CWD = flutter_app/).
const String _passionImages = '../ml_pipeline/data/raw/passion/images';
const String _pairedModel = '../ml_pipeline/outputs/tflite/dermatriage_float32.tflite';
const String _outputDir = '../ml_pipeline/outputs/integration';

const int _imageCount = 8;
const int _tensorLength = 1 * 224 * 224 * 3;

/// A reproducible pseudo-random tensor. The same generator is mirrored in
/// Python so both engines see bit-identical input without shipping a fixture.
Float32List _fixedTensor(int seed) {
  final Float32List t = Float32List(_tensorLength);
  // Numerical Recipes LCG — trivially portable to Python.
  int state = seed;
  for (int i = 0; i < _tensorLength; i++) {
    state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
    final double u = state / 4294967296.0; // [0,1)
    t[i] = -2.1179 + u * (2.6400 + 2.1179); // span the normalised range
  }
  return t;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, dynamic> report = <String, dynamic>{};

  test('app pipeline: bundled asset model over real PASSION images', () async {
    final Directory dir = Directory(_passionImages);
    expect(dir.existsSync(), isTrue, reason: 'PASSION images not found at $_passionImages');

    final List<File> images = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.toLowerCase().endsWith('.jpg'))
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));
    final List<File> sample = images.take(_imageCount).toList();
    expect(sample, isNotEmpty);

    final SkinTriageInterpreter interpreter = SkinTriageInterpreter();
    await interpreter.load(); // bundled asset — the model the app ships
    expect(interpreter.isLoaded, isTrue);

    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (final File f in sample) {
      final Uint8List bytes = await f.readAsBytes();
      final Float32List input = ImageProcessor.preprocess(bytes);
      expect(input.length, _tensorLength);

      final List<double> logits = interpreter.predict(input);
      final TriagePrediction pred = DiseaseClassMapper.mapLogits(logits);

      rows.add(<String, dynamic>{
        'image': f.uri.pathSegments.last,
        'logits': logits,
        'probabilities': pred.probabilities,
        'classIndex': pred.classIndex,
        'classId': pred.classId,
        'confidence': pred.confidence,
        'outcome': pred.outcome.name,
        // Tensor stats let Python verify the preprocessing agrees before
        // blaming the model for any difference.
        'inputMin': input.reduce((double a, double b) => a < b ? a : b),
        'inputMax': input.reduce((double a, double b) => a > b ? a : b),
        'inputMean': input.reduce((double a, double b) => a + b) / input.length,
      });
      // ignore: avoid_print
      print('  ${f.uri.pathSegments.last.padRight(22)} -> '
          '${pred.classId.padRight(13)} conf ${pred.confidence.toStringAsFixed(4)}');
    }
    interpreter.dispose();

    report['classIds'] = kModelClassIds;
    report['images'] = rows;
    expect(rows.length, sample.length);
  });

  test('app interpreter: fixed tensors through the paired model', () async {
    final File model = File(_pairedModel);
    expect(model.existsSync(), isTrue, reason: 'Missing $_pairedModel');

    // The same wrapper the app uses, pointed at the checkpoint that has a
    // known PyTorch source (MobileNet_distilled.pth), so the Dart result can be
    // compared against PyTorch directly.
    final SkinTriageInterpreter interpreter = SkinTriageInterpreter();
    await interpreter.load(modelFile: model);
    expect(interpreter.isLoaded, isTrue);

    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    for (int seed = 1; seed <= 4; seed++) {
      final Float32List t = _fixedTensor(seed);
      final List<double> logits = interpreter.predict(t);
      rows.add(<String, dynamic>{'seed': seed, 'logits': logits});
      // ignore: avoid_print
      print('  seed $seed -> ${logits.map((double v) => v.toStringAsFixed(4)).toList()}');
    }
    interpreter.dispose();

    report['fixedTensor'] = rows;
    report['pairedModel'] = 'dermatriage_float32.tflite';
  });

  tearDownAll(() {
    Directory(_outputDir).createSync(recursive: true);
    final File out = File('$_outputDir/flutter_predictions.json');
    out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
    // ignore: avoid_print
    print('\nWrote ${out.path}');
  });
}
