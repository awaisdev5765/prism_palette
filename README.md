# Prism Palette

![pub version](https://img.shields.io/pub/v/prism_palette) ![pub points](https://img.shields.io/pub/points/prism_palette?label=points&color=green) ![pub likes](https://img.shields.io/pub/likes/prism_palette?label=likes&color=red)

Fast, pure-Flutter color palette extraction — the maintained replacement for
the discontinued [`palette_generator`](https://pub.dev/packages/palette_generator).

Built on [`material_color_utilities`](https://pub.dev/packages/material_color_utilities)
— the pro-grade color science library bundled with Flutter — so results match
Material 3 dynamic color behavior.

## Features

- **Dominant color extraction** from any `ui.Image`
- **The six classic swatches**: `vibrant`, `lightVibrant`, `darkVibrant`,
  `muted`, `lightMuted`, `darkMuted`
- **Region sampling** — extract colors from a sub-rectangle of the image
- **Automatic pixel subsampling** for large images (bounded, fast)
- Pure Dart — no platform channels, works on all six platforms

## Usage

```dart
final palette = await PrismPalette.fromImage(image);

// Dynamic theming
final themeColor = palette.vibrantColor ?? palette.dominantColor;

// Full control
final muted = palette.mutedColor;
final population = palette.populationOf(palette.dominantColor);
```

### Region sampling

```dart
final palette = await PrismPalette.fromImage(
  image,
  region: const Rect.fromLTWH(0, 0, 0.5, 1), // left half only
);
```

### From a list of colors

```dart
final palette = ColorPalette.fromColors([Color(0xFFFF0000), ...]);
```

## Migrating from palette_generator

| palette_generator | prism_palette |
|---|---|
| `PaletteGenerator.fromImageProvider(...)` | `PrismPalette.fromImage(image)` |
| `palette.dominantColor?.color` | `palette.dominantColor` |
| `palette.vibrantColor?.color` | `palette.vibrantColor` |
| `palette.colors` | `palette.colors` |
| `Swatch.population` | `PaletteSwatch.population` |

Part of the [Prism](https://pub.dev/packages/prism_markdown) family — a
cohesive suite of well-tested, pure-Flutter packages.

## License

MIT
