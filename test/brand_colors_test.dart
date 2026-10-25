// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/constants.dart';
import 'package:inklus/l10n/app_localizations_es.dart';
import 'package:inklus/models/cover_colors.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/theme/brand_colors.dart';
import 'package:inklus/ui/widgets/notebook_covers.dart';

/// Contraste WCAG 2.x entre dos colores opacos.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('CoverColors', () {
    test('la paleta tiene los 10 colores de la identidad, en orden', () {
      expect(CoverColors.all, const [
        CoverColors.tinta,
        CoverColors.abismo,
        CoverColors.coral,
        CoverColors.hueso,
        CoverColors.piedra,
        CoverColors.marea,
        CoverColors.musgo,
        CoverColors.ocre,
        CoverColors.vino,
        CoverColors.ciruela,
      ]);
    });

    test('kCoverColors = "Sin color" + la paleta', () {
      expect(kCoverColors.first, isNull);
      expect(kCoverColors.skip(1), CoverColors.all.map((c) => c.toARGB32()));
    });

    test('textOn da Tinta sobre los claros y Hueso sobre el resto', () {
      final light = {
        CoverColors.coral,
        CoverColors.hueso,
        CoverColors.piedra,
        CoverColors.ocre,
      };
      for (final c in CoverColors.all) {
        expect(
          CoverColors.textOn(c),
          light.contains(c) ? BrandColors.tinta : BrandColors.hueso,
          reason: '$c',
        );
      }
    });

    test('el texto de cada tapa pasa AA (≥ 4.5:1)', () {
      for (final c in CoverColors.all) {
        expect(
          contrast(c, CoverColors.textOn(c)),
          greaterThanOrEqualTo(4.5),
          reason: '$c',
        );
      }
    });

    test('textOn también resuelve colores fuera de la paleta', () {
      expect(CoverColors.textOn(const Color(0xFFFFFFFF)), BrandColors.tinta);
      expect(CoverColors.textOn(const Color(0xFF000000)), BrandColors.hueso);
    });
  });

  group('migración de colores viejos', () {
    test('cada color viejo pasa a su equivalente nuevo', () {
      const expected = {
        0xFF3B82F6: CoverColors.abismo, // azul
        0xFF4CAF50: CoverColors.musgo, // verde
        0xFFE53935: CoverColors.vino, // rojo
        0xFFFF9800: CoverColors.ocre, // naranja
        0xFF9C27B0: CoverColors.ciruela, // morado
        0xFFEC407A: CoverColors.coral, // rosa
        0xFF26C6DA: CoverColors.marea, // turquesa
        0xFF78909C: CoverColors.piedra, // gris
      };
      expected.forEach((old, now) {
        expect(CoverColors.migrateLegacy(old), now.toARGB32());
      });
    });

    test('null, colores nuevos y desconocidos no cambian', () {
      expect(CoverColors.migrateLegacy(null), isNull);
      expect(
        CoverColors.migrateLegacy(CoverColors.marea.toARGB32()),
        CoverColors.marea.toARGB32(),
      );
      expect(CoverColors.migrateLegacy(0xFF123456), 0xFF123456);
    });

    test('NotebookMeta y Notebook migran al leer', () {
      final meta = NotebookMeta.fromJson({
        'id': 'a',
        'title': 't',
        'color': 0xFF3B82F6,
      });
      expect(meta.colorValue, CoverColors.abismo.toARGB32());
      final nb = Notebook.fromJson({'id': 'a', 'color': 0xFF78909C});
      expect(nb.colorValue, CoverColors.piedra.toARGB32());
    });
  });

  test('coverColorName nombra los 10 colores', () {
    final l10n = AppLocalizationsEs();
    final names = CoverColors.all
        .map((c) => coverColorName(l10n, c.toARGB32()))
        .toList();
    expect(names, [
      'Tinta',
      'Abismo',
      'Coral',
      'Hueso',
      'Piedra',
      'Marea',
      'Musgo',
      'Ocre',
      'Vino',
      'Ciruela',
    ]);
    expect(coverColorName(l10n, null), l10n.colorNone);
  });
}
