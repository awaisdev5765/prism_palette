/// Palette targets inspired by the Android Palette API, scored with
/// [Hct]-based color science from `material_color_utilities`.
///
/// Each target describes an ideal chroma (colorfulness) and tone (lightness,
/// 0–100). Candidate colors are scored against a target by combining their
/// population in the source image, their chroma distance, and their tone
/// distance — the same three factors the original `palette_generator` used.
library;

import 'package:material_color_utilities/material_color_utilities.dart';

/// The weights used when scoring a candidate color against a target.
///
/// Mirrors the Android Palette defaults: saturation (chroma) 0.24, luminance
/// (tone) 0.52, population 0.24.
final class PaletteWeights {
  /// Weight applied to the chroma-distance score.
  final double chroma;

  /// Weight applied to the tone-distance score.
  final double tone;

  /// Weight applied to the population score.
  final double population;

  /// Creates a weight set. The three weights should sum to `1.0`.
  const PaletteWeights({
    this.chroma = 0.24,
    this.tone = 0.52,
    this.population = 0.24,
  });
}

/// Describes one of the six classic palette swatch targets.
final class PaletteTarget {
  /// Ideal chroma (HCT colorfulness, 0–~130).
  final double targetChroma;

  /// Ideal tone (HCT lightness, 0–100).
  final double targetTone;

  /// Human-readable name, e.g. `vibrant` or `darkMuted`.
  final String name;

  const PaletteTarget._(this.name, this.targetChroma, this.targetTone);

  /// A bright, colorful swatch.
  static const vibrant = PaletteTarget._('vibrant', 48, 50);

  /// A bright, colorful swatch with high lightness.
  static const lightVibrant = PaletteTarget._('lightVibrant', 48, 75);

  /// A colorful swatch with low lightness.
  static const darkVibrant = PaletteTarget._('darkVibrant', 48, 30);

  /// A desaturated swatch.
  static const muted = PaletteTarget._('muted', 20, 50);

  /// A desaturated swatch with high lightness.
  static const lightMuted = PaletteTarget._('lightMuted', 20, 75);

  /// A desaturated swatch with low lightness.
  static const darkMuted = PaletteTarget._('darkMuted', 20, 30);

  /// All six classic targets, in registration order.
  static const List<PaletteTarget> all = [
    vibrant,
    lightVibrant,
    darkVibrant,
    muted,
    lightMuted,
    darkMuted,
  ];
}

/// Scores a single candidate against a [PaletteTarget].
///
/// Returns a value in the range `0..1`, where higher is a better match.
double scoreCandidate({
  required Hct candidate,
  required double population,
  required double maxPopulation,
  required PaletteTarget target,
  PaletteWeights weights = const PaletteWeights(),
}) {
  final chromaScore =
      1.0 - (candidate.chroma - target.targetChroma).abs() / 100.0;
  final toneScore = 1.0 - (candidate.tone - target.targetTone).abs() / 100.0;
  final populationScore =
      maxPopulation <= 0 ? 0.0 : population / maxPopulation;

  double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  return clamp01(chromaScore) * weights.chroma +
      clamp01(toneScore) * weights.tone +
      clamp01(populationScore) * weights.population;
}
