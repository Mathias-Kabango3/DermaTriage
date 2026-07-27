// Phase 1 verification gate for dermatriage_diverse_embedding.tflite.
//
// This file is NOT a re-exported/re-trained checkpoint. It is the exact
// bytes of the currently-shipping dermatriage_diverse.tflite, offline-patched
// (see ml_pipeline: /tmp/tflite_schema/patch_embedding_output.py at the time
// of writing) to additionally expose the pre-classifier pooled-feature
// tensor as a second named output ("embedding"). No weights, ops, or buffers
// were touched — only the primary subgraph's `outputs` list and two tensor
// names — so the classifier is provably unchanged, not just "close".
//
// This test proves that by running both files over the same real PASSION
// images through the real app pipeline (ImageProcessor.preprocess ->
// SkinTriageInterpreter -> DiseaseClassMapper) and asserting:
//
//  1. Logits are bit-identical (not just close) to the original file.
//  2. The embedding output is 576-d and L2-normalised (~1.0) — the model's
//     raw pooled feature is not a unit vector; SkinTriageInterpreter
//     normalises it before returning ModelOutputs.
//
// Run from flutter_app/:  flutter test test/integration/embedding_model_parity_test.dart

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dermatriage/data/datasources/ml/disease_class_mapper.dart';
import 'package:dermatriage/data/datasources/ml/image_processor.dart';
import 'package:dermatriage/data/datasources/ml/tflite_interpreter.dart';
import 'package:flutter_test/flutter_test.dart';

const String _passionImages = '../ml_pipeline/data/raw/passion/images';
const String _originalModel = '../ml_pipeline/outputs/tflite/dermatriage_diverse.tflite';
const int _imageCount = 5;

double _l2Norm(List<double> v) =>
    math.sqrt(v.fold<double>(0.0, (double s, double x) => s + x * x));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('patched model is bit-identical to the original + has a valid embedding',
      () async {
    final Directory dir = Directory(_passionImages);
    expect(dir.existsSync(), isTrue,
        reason: 'PASSION images not found at $_passionImages');
    final List<File> sample = dir
        .listSync()
        .whereType<File>()
        .where((File f) => f.path.toLowerCase().endsWith('.jpg'))
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));
    final List<File> images = sample.take(_imageCount).toList();
    expect(images, isNotEmpty);

    final SkinTriageInterpreter patchedInterp = SkinTriageInterpreter();
    await patchedInterp.load(); // bundled asset — dermatriage_diverse_embedding
    expect(patchedInterp.isLoaded, isTrue);
    expect(patchedInterp.hasEmbedding, isTrue);

    final SkinTriageInterpreter originalInterp = SkinTriageInterpreter();
    await originalInterp.load(modelFile: File(_originalModel));
    expect(originalInterp.isLoaded, isTrue);
    expect(originalInterp.hasEmbedding, isFalse);

    for (final File f in images) {
      final Uint8List bytes = await f.readAsBytes();
      final Float32List input = ImageProcessor.preprocess(bytes);

      final ModelOutputs patchedOut = patchedInterp.run(input);
      final List<double> originalLogits = originalInterp.predict(input);

      final String name = f.uri.pathSegments.last;
      double maxDiff = 0.0;
      for (int i = 0; i < originalLogits.length; i++) {
        final double d = (patchedOut.logits[i] - originalLogits[i]).abs();
        if (d > maxDiff) maxDiff = d;
      }
      final TriagePrediction pred = DiseaseClassMapper.mapLogits(originalLogits);
      // ignore: avoid_print
      print('$name  ${pred.classId}(${pred.confidence.toStringAsFixed(4)})  '
          'maxLogitDiff=${maxDiff.toStringAsExponential(2)}');

      expect(maxDiff, equals(0.0),
          reason: '$name: patching the model changed its logits');

      expect(patchedOut.embedding, isNotNull);
      expect(patchedOut.embedding!.length, 576);
      final double norm = _l2Norm(patchedOut.embedding!);
      // ignore: avoid_print
      print('$name  embedding L2 norm=${norm.toStringAsFixed(4)}');
      expect(norm, closeTo(1.0, 0.01));
    }

    patchedInterp.dispose();
    originalInterp.dispose();
  });
}
