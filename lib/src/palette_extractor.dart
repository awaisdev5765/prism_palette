import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show Rect;
import 'package:material_color_utilities/material_color_utilities.dart';

import 'color_palette.dart';
import 'palette_target.dart';

/// Extracts a [ColorPalette] from raw ARGB pixel data.
final class PaletteExtractor {
  PaletteExtractor._();

  /// Quantizes [argbPixels] and produces a [ColorPalette].
  ///
  /// [maxColors] controls how many distinct colors the quantizer keeps
  /// (higher values produce richer but slower palettes). [desiredColors]
  /// controls how many ranked colors are returned in [ColorPalette.colors].
  static Future<ColorPalette> extract(
    List<int> argbPixels, {
    int maxColors = 64,
    int desiredColors = 16,
    PaletteWeights weights = const PaletteWeights(),
  }) async {
    if (argbPixels.isEmpty) {
      throw ArgumentError.value(argbPixels, 'argbPixels', 'must not be empty');
    }

    final quantizer = QuantizerCelebi();
    final result = await quantizer.quantize(argbPixels, maxColors);

    // Score ranks the quantized colors by suitability; put them first so
    // `dominantColor` matches the recommended color.
    final ranked = Score.score(result.colorToCount, desired: desiredColors).toSet();

    final candidates = <int, int>{
      for (final argb in ranked) argb: result.colorToCount[argb] ?? 0,
    };
    for (final entry in result.colorToCount.entries) {
      candidates.putIfAbsent(entry.key, () => entry.value);
    }

    return ColorPalette.fromPopulations(
      candidates,
      maxColors: candidates.length.clamp(1, 128),
      weights: weights,
    );
  }

  /// Extracts a [ColorPalette] from a source image, sampling pixels to keep
  /// the work bounded.
  ///
  /// [maxSamplePixels] caps how many pixels are analyzed: larger images are
  /// subsampled with a uniform stride, which preserves the dominant colors
  /// while keeping extraction fast. [region] limits sampling to a
  /// normalized sub-rectangle of the image (values 0..1), mirroring the
  /// region support of the original `palette_generator`.
  static Future<ColorPalette> fromImage(
    ui.Image image, {
    int maxColors = 64,
    int desiredColors = 16,
    int maxSamplePixels = 128 * 128,
    Rect? region,
    PaletteWeights weights = const PaletteWeights(),
  }) async {
    final width = image.width;
    final height = image.height;
    if (width <= 0 || height <= 0) {
      throw ArgumentError.value(image, 'image', 'must have non-empty bounds');
    }

    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) {
      throw StateError('Failed to read pixel data from the source image');
    }
    final bytes = byteData.buffer.asUint8List();

    // Normalized sampling region (defaults to the full image).
    final rect = (region ?? Rect.zero).normalize();
    final x0 = (rect.left * width).floor().clamp(0, width - 1);
    final x1 = (rect.right * width).ceil().clamp(1, width);
    final y0 = (rect.top * height).floor().clamp(0, height - 1);
    final y1 = (rect.bottom * height).ceil().clamp(1, height);
    final regionWidth = x1 - x0;
    final regionHeight = y1 - y0;
    final regionPixelCount = regionWidth * regionHeight;

    // Uniform stride so that the number of sampled pixels stays close to
    // maxSamplePixels without ever exceeding the actual region size.
    final stride = regionPixelCount <= maxSamplePixels
        ? 1
        : (regionPixelCount / maxSamplePixels).ceil();

    final pixels = <int>[];
    for (var y = y0; y < y1; y += stride) {
      for (var x = x0; x < x1; x += stride) {
        final offset = (y * width + x) * 4;
        final r = bytes[offset];
        final g = bytes[offset + 1];
        final b = bytes[offset + 2];
        pixels.add(0xFF000000 | (r << 16) | (g << 8) | b);
      }
    }

    return extract(
      pixels,
      maxColors: maxColors,
      desiredColors: desiredColors,
      weights: weights,
    );
  }
}

extension _NormalizedRect on Rect {
  Rect normalize() {
    final l = left < 0 ? 0.0 : (left > 1 ? 1.0 : left);
    final t = top < 0 ? 0.0 : (top > 1 ? 1.0 : top);
    final r = right < l ? l : (right > 1 ? 1.0 : right);
    final b = bottom < t ? t : (bottom > 1 ? 1.0 : bottom);
    return Rect.fromLTRB(l, t, r, b);
  }
}

