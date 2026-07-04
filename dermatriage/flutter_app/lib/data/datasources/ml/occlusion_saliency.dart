import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/constants/app_constants.dart';
import 'image_processor.dart';

/// Generates an occlusion-based saliency heatmap that works with a plain TFLite
/// model — using only forward passes (no gradients).
///
/// A grey patch is slid across the image in a grid. For each position the model
/// is re-run and the drop in the target class's probability is measured: the
/// larger the drop, the more important that region was to the prediction. The
/// per-region importances are splatted back onto a full-resolution map and
/// rendered as a colour heatmap (PNG with per-pixel alpha proportional to
/// importance, so unimportant regions stay transparent).
///
/// This approximates Grad-CAM and is presented in the UI as a "region of
/// interest", not a literal Grad-CAM.
class OcclusionSaliency {
  /// Square model input size (224).
  final int size;

  /// Side length of the occluding patch, in pixels.
  final int patch;

  /// Step between patch positions, in pixels (overlap when < [patch]).
  final int stride;

  OcclusionSaliency({
    this.size = AppConstants.imageSize,
    this.patch = 56,
    this.stride = 28,
  });

  /// Normalised value of a mid-grey occluder (128/255) per channel, matching
  /// the model's ImageNet normalisation.
  static final List<double> _greyNorm = <double>[
    for (int c = 0; c < 3; c++)
      (128.0 / 255.0 - ImageProcessor.imagenetMean[c]) /
          ImageProcessor.imagenetStd[c],
  ];

  /// Patch start offsets along one axis, always including the final flush
  /// position so the whole image is covered.
  List<int> _starts() {
    final List<int> s = <int>[];
    for (int p = 0; p + patch <= size; p += stride) {
      s.add(p);
    }
    final int last = size - patch;
    if (s.isEmpty || s.last != last) s.add(last);
    return s;
  }

  /// Build a heatmap PNG explaining [targetIndex] for the already-normalised
  /// [base] tensor (NHWC `1*size*size*3` from [ImageProcessor.preprocess]).
  ///
  /// [predict] runs the model on a tensor and returns its raw logits. The call
  /// yields to the event loop periodically so the UI stays responsive during
  /// the many forward passes.
  ///
  /// Returns PNG bytes, or null if the heatmap is degenerate (no signal).
  Future<Uint8List?> generate({
    required Float32List base,
    required List<double> Function(Float32List) predict,
    required int targetIndex,
  }) async {
    final double baseProb = _softmaxAt(predict(base), targetIndex);

    final List<int> xs = _starts();
    final List<int> ys = _starts();

    final Float64List sum = Float64List(size * size);
    final Int32List count = Int32List(size * size);

    int done = 0;
    for (final int py in ys) {
      for (final int px in xs) {
        final Float32List occluded = Float32List.fromList(base);
        _occlude(occluded, px, py);
        final double prob = _softmaxAt(predict(occluded), targetIndex);
        final double importance = math.max(0.0, baseProb - prob);

        for (int y = py; y < py + patch; y++) {
          final int row = y * size;
          for (int x = px; x < px + patch; x++) {
            sum[row + x] += importance;
            count[row + x] += 1;
          }
        }

        // Yield every few passes so spinner frames can render.
        if (++done % 8 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    }

    // Per-pixel mean importance, then normalise to [0, 1].
    final Float64List importance = Float64List(size * size);
    double maxVal = 0.0;
    for (int i = 0; i < importance.length; i++) {
      final int c = count[i];
      final double v = c > 0 ? sum[i] / c : 0.0;
      importance[i] = v;
      if (v > maxVal) maxVal = v;
    }
    if (maxVal <= 1e-6) return null; // no region changed the prediction

    return _renderPng(importance, maxVal);
  }

  /// Overwrite the [patch]×[patch] region at ([px], [py]) with grey.
  void _occlude(Float32List t, int px, int py) {
    for (int y = py; y < py + patch; y++) {
      final int row = y * size;
      for (int x = px; x < px + patch; x++) {
        final int base = (row + x) * 3;
        t[base] = _greyNorm[0];
        t[base + 1] = _greyNorm[1];
        t[base + 2] = _greyNorm[2];
      }
    }
  }

  /// Render the normalised importance buffer as an RGBA heatmap PNG.
  Uint8List _renderPng(Float64List importance, double maxVal) {
    final img.Image out = img.Image(width: size, height: size, numChannels: 4);
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final double v = (importance[y * size + x] / maxVal).clamp(0.0, 1.0);
        final List<int> rgb = _jet(v);
        // Alpha grows with importance so cool/empty regions stay transparent.
        final int a = (v * 255).round();
        out.setPixelRgba(x, y, rgb[0], rgb[1], rgb[2], a);
      }
    }
    return Uint8List.fromList(img.encodePng(out));
  }

  /// Softmax probability of [index] from raw [logits].
  double _softmaxAt(List<double> logits, int index) {
    final double maxLogit = logits.reduce(math.max);
    double sum = 0.0;
    for (final double l in logits) {
      sum += math.exp(l - maxLogit);
    }
    return math.exp(logits[index] - maxLogit) / sum;
  }

  /// "Jet" colormap: maps v in [0,1] to an RGB triple (blue→green→red).
  List<int> _jet(double v) {
    double clamp(double x) => x.clamp(0.0, 1.0);
    final double r = clamp(math.min(4 * v - 1.5, -4 * v + 4.5));
    final double g = clamp(math.min(4 * v - 0.5, -4 * v + 3.5));
    final double b = clamp(math.min(4 * v + 0.5, -4 * v + 2.5));
    return <int>[(r * 255).round(), (g * 255).round(), (b * 255).round()];
  }
}
