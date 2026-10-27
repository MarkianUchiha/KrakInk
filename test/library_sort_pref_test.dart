// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/services/app_paths.dart';
import 'package:inklus/services/storage_service.dart';
import 'package:inklus/ui/notebook_library.dart';
import 'package:inklus/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El orden de la biblioteca se recuerda entre aperturas, igual que la vista.
void main() {
  late Directory data;

  setUp(() {
    data = Directory.systemTemp.createTempSync('krakink_sort_');
    AppPaths.rootOverride = data;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AppPaths.rootOverride = null;
    try {
      if (data.existsSync()) data.deleteSync(recursive: true);
    } on FileSystemException {
      // El sistema limpia la carpeta temporal después.
    }
  });

  Future<void> pumpLibrary(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // Una key nueva fuerza un State nuevo, como al reabrir la app.
        key: UniqueKey(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: const NotebookLibraryScreen(),
      ),
    );
    // Con el reloj falso, cada paso de E/S real (índice, preferencias)
    // necesita su propio ciclo de espera real + pump. El chip de orden solo
    // aparece cuando ya cargaron los cuadernos.
    Future<void> cycle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    for (var i = 0; i < 40 && find.byType(ActionChip).evaluate().isEmpty; i++) {
      await cycle();
    }
    // Las preferencias cargan en paralelo al índice.
    for (var i = 0; i < 3; i++) {
      await cycle();
    }
  }

  testWidgets('elegir A-Z sobrevive a reconstruir la pantalla', (tester) async {
    await tester.runAsync(
      () => StorageService.instance.createNotebook(title: 'Cuaderno 1'),
    );
    await pumpLibrary(tester);
    expect(find.text('Más recientes'), findsOneWidget);

    await tester.tap(find.text('Más recientes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Título A → Z'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre A–Z'), findsOneWidget);

    await pumpLibrary(tester);
    expect(find.text('Nombre A–Z'), findsOneWidget);
  });
}
