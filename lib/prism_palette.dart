/// Prism Palette — the maintained replacement for the discontinued
/// `palette_generator`.
///
/// Extracts dominant colors and classic swatches (vibrant, muted, light and
/// dark variants) from images or explicit color lists, built on the
/// pro-grade color science of `material_color_utilities` — the same library
/// that powers Material 3 dynamic color in Flutter.
///
/// ```dart
/// final palette = await PrismPalette.fromImage(image);
/// final themeColor = palette.vibrantColor ?? palette.dominantColor;
/// ```
///
/// See the README for the full migration guide from `palette_generator`.
library;

export 'package:flutter/painting.dart'
    show Color, Rect; // convenience re-exports

export 'src/color_palette.dart';
export 'src/palette_extractor.dart';
export 'src/palette_target.dart';
