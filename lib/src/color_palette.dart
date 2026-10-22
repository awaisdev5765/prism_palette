import 'package:flutter/painting.dart' show Color;

import 'package:material_color_utilities/material_color_utilities.dart';

import 'palette_target.dart';

/// A color selected from a palette, together with how prominently it
/// appeared in the source image.
///
/// Mirrors the `Palette.Swatch` concept from the original
/// `palette_generator` package: [color] plus [population] (the number of
/// pixels the color represented after quantization).
final class PaletteSwatch {
  /// The quantized color, as an ARGB 32-bit integer.
  final int argb;

  /// Number of source pixels represented by this color after quantization.
  final int population;

  const PaletteSwatch({required this.argb, required this.population});

  /// The color as a Flutter [Color].
  Color get color => Color(argb);

  /// The color as an [Hct] value, giving access to hue, chroma and tone.
  Hct get hct => Hct.fromInt(argb);

  @override
  bool operator ==(Object other) =>
      other is PaletteSwatch &&
      other.argb == argb &&
      other.population == population;

  @override
  int get hashCode => Object.hash(argb, population);

  @override
  String toString() => 'PaletteSwatch($color, population: $population)';
}

/// A palette extracted from a source image: a ranked list of dominant
/// colors plus the six classic Android-Palette swatches (vibrant, muted,
/// and their light/dark variants).
///
/// Obtain an instance with [ColorPalette.fromImage],
/// [ColorPalette.fromPixels] or [ColorPalette.fromColors].
final class ColorPalette {
  /// All candidate swatches found in the source, sorted by descending
  /// population.
  final List<PaletteSwatch> swatches;

  /// The six classic swatch targets and their best match, if any.
  ///
  /// Targets without a suitable candidate in the source image are absent
  /// from the map — check with [targetColor] or the named getters.
  final Map<String, PaletteSwatch> targetSwatches;

  const ColorPalette._(this.swatches, this.targetSwatches);

  /// The single most represented color in the source image.
  ///
  /// Never null when the palette was extracted from a non-empty source.
  Color get dominantColor =>
      Color(swatches.isEmpty ? 0xFF000000 : swatches.first.argb);

  /// The dominant color as a [PaletteSwatch], including its population.
  PaletteSwatch? get dominantSwatch => swatches.isEmpty ? null : swatches.first;

  /// All extracted colors, ranked from most to least represented.
  List<Color> get colors =>
      swatches.map((s) => s.color).toList(growable: false);

  /// Population (pixel count) for a specific color, or `null` if the color
  /// is not part of the palette.
  int? populationOf(Color color) {
    for (final s in swatches) {
      if (s.color == color) return s.population;
    }
    return null;
  }

  /// The best match for a named target (e.g. `'vibrant'`), or `null`.
  ///
  /// Valid names are the [PaletteTarget.all] names: `vibrant`,
  /// `lightVibrant`, `darkVibrant`, `muted`, `lightMuted`, `darkMuted`.
  PaletteSwatch? swatchFor(String name) => targetSwatches[name];

  /// The most vibrant color, or `null` when the source has no saturated
  /// colors.
  Color? get vibrantColor => targetSwatches[PaletteTarget.vibrant.name]?.color;

  /// A bright vibrant color (light tone), or `null`.
  Color? get lightVibrantColor =>
      targetSwatches[PaletteTarget.lightVibrant.name]?.color;

  /// A vibrant color with low lightness, or `null`.
  Color? get darkVibrantColor =>
      targetSwatches[PaletteTarget.darkVibrant.name]?.color;

  /// A desaturated color, or `null`.
  Color? get mutedColor => targetSwatches[PaletteTarget.muted.name]?.color;

  /// A desaturated, light color, or `null`.
  Color? get lightMutedColor =>
      targetSwatches[PaletteTarget.lightMuted.name]?.color;

  /// A desaturated, dark color, or `null`.
  Color? get darkMutedColor =>
      targetSwatches[PaletteTarget.darkMuted.name]?.color;

  /// Builds a palette from quantized colors and their populations.
  ///
  /// [candidates] maps an ARGB color to the number of source pixels it
  /// represented. The [maxColors] most populated candidates are kept and
  /// ranked; each of the six classic targets is then matched against them.
  static ColorPalette fromPopulations(
    Map<int, int> candidates, {
    int maxColors = 16,
    PaletteWeights weights = const PaletteWeights(),
  }) {
    final swatches = candidates.entries
        .map((e) => PaletteSwatch(argb: e.key, population: e.value))
        .toList()
      ..sort((a, b) => b.population.compareTo(a.population));

    final trimmed = swatches.take(maxColors).toList(growable: false);
    final maxPopulation =
        trimmed.isEmpty ? 0.0 : trimmed.first.population.toDouble();

    final targets = <String, PaletteSwatch>{};
    for (final target in PaletteTarget.all) {
      PaletteSwatch? best;
      var bestScore = -1.0;
      for (final swatch in trimmed) {
        final hct = Hct.fromInt(swatch.argb);
        final score = scoreCandidate(
          candidate: hct,
          population: swatch.population.toDouble(),
          maxPopulation: maxPopulation,
          target: target,
          weights: weights,
        );
        if (score > bestScore) {
          bestScore = score;
          best = swatch;
        }
      }
      if (best != null) {
        targets[target.name] = best;
      }
    }

    return ColorPalette._(trimmed, targets);
  }

  /// Builds a palette from an explicit list of colors.
  ///
  /// Handy when colors were extracted elsewhere; every color receives a
  /// population of 1.
  static ColorPalette fromColors(
    Iterable<Color> colors, {
    PaletteWeights weights = const PaletteWeights(),
  }) {
    final candidates = <int, int>{
      for (final c in colors) c.toARGB32(): 1,
    };
    return fromPopulations(candidates, weights: weights);
  }
}
