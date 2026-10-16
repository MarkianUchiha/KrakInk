// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/app.dart' show resolveAppLocale;
import 'package:inklus/l10n/app_localizations.dart';

/// Las traducciones no pueden quedarse atrás: toda clave del español (la
/// fuente) debe existir en cada idioma, con los mismos marcadores {…}.
void main() {
  const locales = ['en', 'pt', 'fr', 'de'];

  Map<String, dynamic> arb(String locale) =>
      jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
          as Map<String, dynamic>;

  Set<String> keys(Map<String, dynamic> m) =>
      m.keys.where((k) => !k.startsWith('@')).toSet();

  Set<String> placeholders(String text) =>
      RegExp(r'\{(\w+)[,}]').allMatches(text).map((m) => m.group(1)!).toSet();

  final es = arb('es');

  for (final locale in locales) {
    final tr = arb(locale);

    test('$locale tiene todas las claves del español y ninguna de más', () {
      expect(keys(tr), keys(es));
    });

    test('$locale: mismos marcadores en cada traducción', () {
      for (final k in keys(es)) {
        expect(placeholders(tr[k] as String), placeholders(es[k] as String),
            reason: '$locale/$k');
      }
    });

    test('$locale: ninguna traducción vacía', () {
      for (final k in keys(es)) {
        expect((tr[k] as String).trim(), isNotEmpty, reason: '$locale/$k');
      }
    });
  }

  group('idioma del sistema', () {
    const supported = AppLocalizations.supportedLocales;
    test('respeta el primer idioma traducido, incluso regional', () {
      expect(resolveAppLocale([const Locale('pt', 'BR')], supported).languageCode, 'pt');
      expect(resolveAppLocale([const Locale('ja'), const Locale('fr')], supported).languageCode, 'fr');
    });
    test('sin traducción cae en inglés (no en alemán)', () {
      expect(resolveAppLocale([const Locale('ja')], supported), const Locale('en'));
      expect(resolveAppLocale(null, supported), const Locale('en'));
    });
  });
}
