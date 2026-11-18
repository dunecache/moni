import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:moni/kanso/kanso_tokens.dart';

void main() {
  group('Kanso semantic tokens', () {
    test('Morning Matcha matches the canonical v1.3.0 roles', () {
      final c = KansoColors.morningMatcha;
      expect(c.background.value, 0xFFF3F1E9);
      expect(c.surface.value, 0xFFE8E5DA);
      expect(c.surfaceElevated.value, 0xFFFAF9F4);
      expect(c.surfaceSunken.value, 0xFFE2DED2);
      expect(c.textPrimary.value, 0xFF34382F);
      expect(c.accentPrimary.value, 0xFF89977A);
      expect(c.accentStrong.value, 0xFF5C664A);
      expect(c.onAccent.value, 0xFF171E16);
      expect(c.selection.value, 0xFFDCE2D1);
      expect(c.selectedInk.value, 0xFF3D4A33);
      expect(c.focus.value, 0xFF626D4F);
    });

    test('Evening Zen matches the revised v1.3.0 roles', () {
      final c = KansoColors.eveningZen;
      expect(c.background.value, 0xFF171F18);
      expect(c.surface.value, 0xFF263326);
      expect(c.surfaceElevated.value, 0xFF364735);
      expect(c.surfaceSunken.value, 0xFF10160F);
      expect(c.textPrimary.value, 0xFFE9EEE2);
      expect(c.textMuted.value, 0xFFB2BBAB);
      expect(c.borderSubtle.value, 0xFF3D4A3B);
      expect(c.accentPrimary.value, 0xFFB0C39C);
      expect(c.accentStrong.value, 0xFFD2E4BB);
      expect(c.onAccent.value, 0xFF171E16);
      expect(c.floating.value, 0xFF4A5B45);
      expect(c.selectedInk.value, 0xFFD2E4BB);
    });

    test('on-accent ink passes AA on both accent fills, in both modes', () {
      double channel(int argb, int shift) {
        final value = (argb >> shift & 0xFF) / 255.0;
        return value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
      }

      double luminance(int argb) =>
          0.2126 * channel(argb, 16) + 0.7152 * channel(argb, 8) + 0.0722 * channel(argb, 0);

      double contrast(int a, int b) {
        final light = math.max(luminance(a), luminance(b));
        final dark = math.min(luminance(a), luminance(b));
        return (light + 0.05) / (dark + 0.05);
      }

      for (final entry in <String, KansoColors>{
        'Morning Matcha': KansoColors.morningMatcha,
        'Evening Zen': KansoColors.eveningZen,
      }.entries) {
        final c = entry.value;
        expect(contrast(c.onAccent.value, c.accentPrimary.value), greaterThanOrEqualTo(4.5),
            reason: 'Filled-button label must pass WCAG AA in ${entry.key}');
      }
    });

    test('raw color values only live in the token adapter', () {
      final lib = Directory('lib');
      final offenders = <String>[];
      for (final file in lib.listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('kanso_tokens.dart')) continue;
        final source = file.readAsStringSync();
        if (RegExp(r'0xFF[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{6}').hasMatch(source)) {
          offenders.add(file.path);
        }
      }
      expect(offenders, isEmpty, reason: 'Found raw colors in: ${offenders.join(', ')}');
    });
  });
}
