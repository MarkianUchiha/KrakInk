// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/brand.dart';

void main() {
  // Las claves (`errNotInklus`…) son identificadores de código y se renombran
  // aparte; aquí solo importa lo que ve el usuario.
  test('ningún texto traducido menciona la marca anterior', () {
    final arbs = Directory(
      'lib/l10n',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));
    expect(arbs, isNotEmpty);

    for (final arb in arbs) {
      final json = jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
      json.forEach((key, value) {
        if (key.startsWith('@') || value is! String) return;
        expect(
          value.toLowerCase(),
          isNot(contains('inklus')),
          reason: '${arb.path} → $key',
        );
      });
    }
  });

  test('la app y el manifest de Android usan la misma identidad', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();
    expect(manifest, contains('android:label="${Brand.appName}"'));
    expect(manifest, contains(Brand.mimeType));
    expect(manifest, contains('.${Brand.fileExtension}"'));

    final activity = File(
      'android/app/src/main/kotlin/com/markidev/krakink/MainActivity.kt',
    ).readAsStringSync();
    expect(activity, contains('"${Brand.openChannel}"'));
  });
}
