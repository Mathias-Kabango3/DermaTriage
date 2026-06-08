import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/constants/app_constants.dart';

/// Converts raw image bytes into the normalised tensor the model expects.
class ImageProcessor {
  ImageProcessor._();

  // ImageNet normalisation statistics (must match training preprocessing).
  static const List<double> _mean = <double>[0.485, 0.456, 0.406];
  static const List<double> _std = <double>[0.229, 0.224, 0.225];

  /// Decode, resize to 224x224 and ImageNet-normalise an image.
  ///
  /// Returns a [Float32List] of length `1 * 224 * 224 * 3` in NHWC order.
  /// Throws [FormatException] if the bytes cannot be decoded.
  static Float32List preprocess(Uint8List imageBytes) {
    final img.Image? decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      throw const FormatException('Unable to decode image bytes.');
    }

    const int size = AppConstants.imageSize;
    final img.Image resized = img.copyResize(
      decoded,
      width: size,
      height: size,
    );

    final Float32List output = Float32List(1 * size * size * 3);
    int i = 0;
    for (int y = 0; y < size; y++) {
      for (int x = 0; x < size; x++) {
        final img.Pixel pixel = resized.getPixel(x, y);
        // Normalise each channel: (value/255 - mean) / std.
        output[i++] = (pixel.r / 255.0 - _mean[0]) / _std[0];
        output[i++] = (pixel.g / 255.0 - _mean[1]) / _std[1];
        output[i++] = (pixel.b / 255.0 - _mean[2]) / _std[2];
      }
    }
    return output;
  }
}
