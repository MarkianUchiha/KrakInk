// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/services/app_paths.dart';
import 'package:inklus/ui/create_notebook_screen.dart';
import 'package:inklus/ui/home_screen.dart';
import 'package:inklus/ui/note_list_screen.dart';
import 'package:inklus/ui/notebook_library.dart';
import 'package:inklus/ui/onboarding_screen.dart';
import 'package:inklus/ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El teléfono también es target: ninguna pantalla principal puede
/// desbordarse en anchos de teléfono. Un overflow hace fallar el test solo.
void main() {
  // Anchos lógicos reales: Android compacto común y Pixel 6.
  const sizes = {
    '360x800': Size(360, 800),
    '411x914': Size(411, 914),
    'tablet 1280x800': Size(1280, 800),
  };

  late Directory data;

  setUp(() {
    data = Directory.systemTemp.createTempSync('krakink_phone_');
    AppPaths.rootOverride = data;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    AppPaths.rootOverride = null;
    // En Windows el editor puede seguir teniendo abierto un archivo de la
    // carpeta temporal; no es parte de lo que este test verifica.
    try {
      if (data.existsSync()) data.deleteSync(recursive: true);
    } on FileSystemException {
      // El sistema limpia la carpeta temporal después.
    }
  });

  Future<void> pumpScreen(WidgetTester tester, Size size, Widget home) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: home,
      ),
    );
    // Deja terminar la E/S real de initState (índice, preferencias).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final entry in sizes.entries) {
    final size = entry.value;
    group('teléfono ${entry.key}', () {
      testWidgets('bienvenida', (tester) async {
        await pumpScreen(tester, size, const OnboardingScreen());
      });

      testWidgets('biblioteca', (tester) async {
        await pumpScreen(tester, size, const NotebookLibraryScreen());
      });

      testWidgets('crear cuaderno, ambos pasos', (tester) async {
        await pumpScreen(
          tester,
          size,
          const CreateNotebookScreen(notebookCount: 0),
        );
        final next = find.text('Siguiente');
        await tester.ensureVisible(next);
        await tester.pump();
        await tester.tap(next);
        await tester.pump(const Duration(milliseconds: 500));
      });

      testWidgets('lista de notas', (tester) async {
        await pumpScreen(
          tester,
          size,
          NoteListScreen(notebook: Notebook.newBlank(title: 'Cuaderno 1')),
        );
      });

      testWidgets('editor', (tester) async {
        final nb = Notebook.newBlank(title: 'Cuaderno 1');
        await pumpScreen(
          tester,
          size,
          HomeScreen(note: nb.notes.first, notebookId: nb.id),
        );
      });
    });
  }
}
