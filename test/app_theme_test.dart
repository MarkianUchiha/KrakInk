// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/ui/theme/app_theme.dart';
import 'package:inklus/ui/theme/brand_colors.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, theme) in [
    ('claro', AppTheme.light()),
    ('oscuro', AppTheme.dark()),
  ]) {
    group('tema $name', () {
      final s = theme.colorScheme;

      test('pares de texto/fondo pasan AA (≥ 4.5:1)', () {
        final pairs = {
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurfaceVariant/surfaceContainerHighest':
              (s.onSurfaceVariant, s.surfaceContainerHighest),
          'onSurface/surfaceContainerHigh': (s.onSurface, s.surfaceContainerHigh),
          'primary/surface': (s.primary, s.surface),
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onSecondary/secondary': (s.onSecondary, s.secondary),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'error/surface': (s.error, s.surface),
          'onError/error': (s.onError, s.error),
        };
        pairs.forEach((label, p) {
          expect(
            contrast(p.$1, p.$2),
            greaterThanOrEqualTo(4.5),
            reason: label,
          );
        });
      });

      test('el error no se confunde con el primario coral', () {
        expect(s.error, isNot(s.primary));
        final hError = HSLColor.fromColor(s.error).hue;
        final hPrimary = HSLColor.fromColor(s.primary).hue;
        // Carmín (~340°) frente a coral (~15°): separación de matiz real.
        final diff = (hError - hPrimary).abs();
        expect(diff > 180 ? 360 - diff : diff, greaterThan(25));
      });
    });
  }

  test('superficies y primarios de la identidad', () {
    expect(AppTheme.light().colorScheme.surface, BrandColors.hueso);
    expect(AppTheme.light().colorScheme.onSurface, BrandColors.tinta);
    expect(AppTheme.light().colorScheme.primary, BrandColors.coralText);
    expect(AppTheme.dark().colorScheme.surface, BrandColors.tinta);
    expect(AppTheme.dark().colorScheme.onSurface, BrandColors.hueso);
    expect(AppTheme.dark().colorScheme.primary, BrandColors.coral);
    expect(AppTheme.light().colorScheme.secondary, BrandColors.abismo);
  });
}
