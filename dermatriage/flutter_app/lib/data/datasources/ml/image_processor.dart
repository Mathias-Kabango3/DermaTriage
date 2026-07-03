import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../../core/constants/app_constants.dart';

/// Converts raw image bytes into the normalised tensor the model expects.
class ImageProcessor {
  ImageProcessor._();

  // ImageNet normalisation statistics (must match training preprocessing).
  /// Per-channel ImageNet mean (RGB), exposed for the saliency occluder.
  static const List<double> imagenetMean = <double>[0.485, 0.456, 0.406];

  /// Per-channel ImageNet std (RGB), exposed for the saliency occluder.
  static const List<double> imagenetStd = <double>[0.229, 0.224, 0.225];

  static const List<double> _mean = imagenetMean;
  static const List<double> _std = imagenetStd;

  /// Decode and convert an image to the model input tensor, matching the
  /// training pipeline EXACTLY:
  ///
  ///   transforms.Resize((224, 224))   -> direct resize (squash), no crop
  ///   transforms.ToTensor()           -> RGB, /255 -> [0,1]
  ///   transforms.Normalize(mean, std) -> ImageNet per-channel normalisation
  ///
  /// EXIF orientation is baked first so phone photos are upright (dataset
  /// images are already upright). Resizing uses area-averaging interpolation to
  /// approximate PIL/torchvision's antialiased bilinear — point-sampling
  /// (nearest) a multi-megapixel photo down to 224 produces aliased noise and
  /// breaks predictions.
  ///
  /// Returns a [Float32List] of length `1 * 224 * 224 * 3` in NHWC order.
  /// Throws [FormatException] if the bytes cannot be decoded.
  static Float32List preprocess(Uint8List imageBytes) {
    final img.Image? raw = img.decodeImage(imageBytes);
    if (raw == null) {
      throw const FormatException('Unable to decode image bytes.');
    }

    final img.Image decoded = img.bakeOrientation(raw);

    const int size = AppConstants.imageSize;
    // Direct resize to 224x224 (squash), matching transforms.Resize((224,224)).
    final img.Image resized = img.copyResize(
      decoded,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
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
