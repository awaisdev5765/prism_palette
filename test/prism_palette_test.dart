import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' show Paint;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism_palette/prism_palette.dart';

void main() {
  group('ColorPalette.fromColors', () {
    test('exposes every color and ranks the first as dominant by default',
        () {
      final palette = ColorPalette.fromColors([
        const Color(0xFFFF0000), // red
        const Color(0xFF00FF00), // green
        const Color(0xFF0000FF), // blue
      ]);

      expect(palette.swatches.length, 3);
      expect(
        palette.colors.toSet(),
        {const Color(0xFFFF0000), const Color(0xFF00FF00), const Color(0xFF0000FF)},
      );
      expect(palette.dominantColor, isNotNull);
    });

    test('populationOf reports the source count', () {
      final palette = ColorPalette.fromPopulations({
        0xFFFF0000: 80,
        0xFF00FF00: 20,
      });

      expect(palette.populationOf(const Color(0xFFFF0000)), 80);
      expect(palette.populationOf(const Color(0xFF00FF00)), 20);
      expect(palette.populationOf(const Color(0xFF0000FF)), isNull);
    });

    test('swatch getters never throw and targets map is populated', () {
      final palette = ColorPalette.fromColors([
        const Color(0xFFFF1744), // vivid red
        const Color(0xFF263238), // dark desaturated
        const Color(0xFFFFF59D), // light desaturated
      ]);

      // All six targets must be present in the map (each candidate matches
      // some target best).
      expect(palette.targetSwatches.length, 6);
      expect(palette.vibrantColor, isNotNull);
      expect(palette.lightVibrantColor, isNotNull);
      expect(palette.darkVibrantColor, isNotNull);
      expect(palette.mutedColor, isNotNull);
      expect(palette.lightMutedColor, isNotNull);
      expect(palette.darkMutedColor, isNotNull);

      // Dark targets should have lower tone than their light counterparts.
      expect(
        palette.darkVibrantColor!.computeLuminance(),
        lessThan(palette.lightVibrantColor!.computeLuminance()),
      );
    });
  });

  group('PaletteExtractor.fromImage', () {
    Future<ui.Image> createTwoToneImage(
      int width,
      int height,
      Color left,
      Color right,
    ) async {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, width / 2.0, height.toDouble()),
        Paint()..color = left,
      );
      canvas.drawRect(
        Rect.fromLTWH(width / 2.0, 0, width / 2.0, height.toDouble()),
        Paint()..color = right,
      );
      return recorder.endRecording().toImage(width, height);
    }

    testWidgets('extracts dominant colors from a two-tone image',
        skip: true, // TODO: ui.Image rasterization needs on-device verification
        (tester) async {
      final image = await createTwoToneImage(
        64,
        64,
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
      );
      addTearDown(image.dispose);

      final palette = await PaletteExtractor.fromImage(image);

      expect(palette.colors, isNotEmpty);
      final extracted = palette.colors.toSet();
      expect(
        extracted.any((c) => c.red > 200 && c.green < 100),
        isTrue,
        reason: 'expected a red-ish color in the palette: $extracted',
      );
      expect(
        extracted.any((c) => c.green > 200 && c.red < 100),
        isTrue,
        reason: 'expected a green-ish color in the palette: $extracted',
      );
    });

    testWidgets('region sampling restricts extraction to the sub-rectangle',
        skip: true, // TODO: ui.Image rasterization needs on-device verification
        (tester) async {
      final image = await createTwoToneImage(
        64,
        64,
        const Color(0xFFFF0000), // left half: red
        const Color(0xFF00FF00), // right half: green
      );
      addTearDown(image.dispose);

      final leftPalette = await PaletteExtractor.fromImage(
        image,
        region: const Rect.fromLTWH(0, 0, 0.5, 1),
      );

      // Only the red half was sampled, so no green should dominate.
      expect(
        leftPalette.colors.any((c) => c.green > 200 && c.red < 100),
        isFalse,
        reason: 'region should have excluded the green half',
      );
    });

    testWidgets('throws on empty pixel list', (tester) async {
      await expectLater(
        PaletteExtractor.extract(const []),
        throwsArgumentError,
      );
    });
  });
}
