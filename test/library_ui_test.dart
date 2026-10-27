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

/// Biblioteca en tablet (1280×800, menú lateral fijo). El flujo completo de
/// carpetas va en integration_test: con el reloj falso de testWidgets, leer
/// un archivo recién escrito con E/S real no termina.
void main() {
  late Directory data;
  final storage = StorageService.instance;

  setUp(() {
    data = Directory.systemTemp.createTempSync('krakink_library_');
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

  /// Con el reloj falso, cada paso de E/S real (índice, library.json,
  /// preferencias) necesita su propio ciclo de espera real + pump.
  Future<void> settle(WidgetTester tester, {int cycles = 6}) async {
    for (var i = 0; i < cycles; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

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
    // El chip de orden solo aparece cuando ya cargaron los cuadernos.
    for (var i = 0; i < 40 && find.byType(ActionChip).evaluate().isEmpty; i++) {
      await settle(tester, cycles: 1);
    }
    await settle(tester, cycles: 3);
  }

  testWidgets('elegir A-Z sobrevive a reconstruir la pantalla', (tester) async {
    await tester.runAsync(() => storage.createNotebook(title: 'Cuaderno 1'));
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

  testWidgets('el menú lateral separa Filtros de Carpetas', (tester) async {
    await tester.runAsync(() => storage.createNotebook(title: 'Cuaderno 1'));
    await pumpLibrary(tester);
    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Carpetas'), findsOneWidget);
    expect(find.byTooltip('Nueva carpeta'), findsOneWidget);
  });
}
