// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/l10n/l10n.dart';
import 'package:inklus/models/library_data.dart';
import 'package:inklus/ui/theme/app_theme.dart';
import 'package:inklus/ui/widgets/folder_sheets.dart';

/// Hojas y diálogos de carpetas, sin disco: lo que devuelven a la biblioteca.
void main() {
  final uni = Folder(id: 'f_uni', name: 'Uni', createdAt: DateTime(2026));
  final casa = Folder(id: 'f_casa', name: 'Casa', createdAt: DateTime(2026));

  /// Monta un botón que abre [open] y guarda su resultado en [result].
  Future<void> pumpOpener<T>(
    WidgetTester tester,
    Future<T> Function(BuildContext) open,
    void Function(T) result,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result(await open(context)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  group('Mover a carpeta', () {
    Future<FolderPick?> pick(WidgetTester tester, String tap) async {
      FolderPick? picked;
      await pumpOpener<FolderPick?>(
        tester,
        (c) =>
            showMoveToFolderSheet(c, folders: [uni, casa], currentId: 'f_uni'),
        (v) => picked = v,
      );
      // La carpeta actual se marca.
      expect(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Uni'),
          matching: find.byIcon(Icons.check),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
      return picked;
    }

    testWidgets('elegir una carpeta devuelve su id', (tester) async {
      expect(await pick(tester, 'Casa'), (id: 'f_casa', createNew: false));
    });

    testWidgets('"Sin carpeta" devuelve id null', (tester) async {
      expect(await pick(tester, 'Sin carpeta'), (id: null, createNew: false));
    });

    testWidgets('"Nueva carpeta" pide crearla', (tester) async {
      expect(await pick(tester, 'Nueva carpeta'), (id: null, createNew: true));
    });
  });

  testWidgets('borrar avisa que los cuadernos no se borran', (tester) async {
    bool? ok;
    await pumpOpener<bool>(
      tester,
      (c) => confirmDeleteFolder(c, uni),
      (v) => ok = v,
    );
    expect(find.textContaining('no se borra ninguno'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(ok, isTrue);
  });

  testWidgets('el nombre se recorta y uno vacío cancela', (tester) async {
    String? name = 'sin tocar';
    await pumpOpener<String?>(
      tester,
      (c) => showFolderNameDialog(c),
      (v) => name = v,
    );
    await tester.enterText(find.byType(TextField), '  Uni  ');
    await tester.tap(find.text('Crear'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(name, 'Uni');

    await tester.tap(find.text('abrir'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Crear'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(name, isNull);
  });
}
