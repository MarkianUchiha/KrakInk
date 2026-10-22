// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/document.dart';
import 'package:inklus/services/error_log.dart';
import 'package:inklus/services/import_service.dart';
import 'package:inklus/services/inklus_format.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  group('ImportService.kindFor', () {
    test('respaldo completo', () {
      expect(ImportService.kindFor({'backup.json', 'index.json', 'notes/a.json'}),
          ImportKind.fullBackup);
      expect(ImportService.kindFor({'index.json'}), ImportKind.fullBackup);
    });

    test('cuaderno .inklus v2 (aunque venga renombrado a .zip)', () {
      expect(ImportService.kindFor({'format.json', 'notebook.json', 'notes/n1.json'}),
          ImportKind.notebook);
    });

    test('.inklus v1 legacy', () {
      expect(ImportService.kindFor({'document.json', 'images/a.png'}),
          ImportKind.legacyDocument);
    });

    test('nota suelta (copia de Drive): format.json + document.json es v1', () {
      expect(ImportService.kindFor({'format.json', 'document.json'}),
          ImportKind.legacyDocument);
    });

    test('otro ZIP → FormatException', () {
      expect(() => ImportService.kindFor({'foo.txt'}), throwsFormatException);
      expect(() => ImportService.kindFor(<String>{}), throwsFormatException);
    });
  });

  test('un .inklus v1 importado queda dentro de su cuaderno', () async {
    final tempDir = Directory.systemTemp.createTempSync('inklus_import_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final storage = StorageService(baseDir: Directory('${tempDir.path}/lib'));
    final doc = Document.newBlank(title: 'Viejo');
    final bytes = await InklusFormat.exportBytes(doc);

    final result = await ImportService.importBytes(
      bytes,
      storage: storage,
      extractTo: Directory('${tempDir.path}/restored'),
    );

    expect(result.kind, ImportKind.legacyDocument);
    final nb = (await storage.loadNotebook(result.notebookId!))!;
    expect(nb.title, 'Viejo');
    expect(nb.notes.single.title, 'Viejo');
    expect(nb.notes.single.id, isNot(doc.id));
  });

  group('OBS-04: fallos de importación en el registro', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('inklus_import_log_');
      ErrorLog.fileProvider = () async => File('${tmp.path}/errors.log');
    });

    tearDown(() => tmp.deleteSync(recursive: true));

    Uint8List zipWith(String name, String content) {
      final data = utf8.encode(content);
      final archive = Archive()..addFile(ArchiveFile(name, data.length, data));
      return Uint8List.fromList(ZipEncoder().encode(archive));
    }

    Future<List<Map<String, dynamic>>> logged() async {
      await ErrorLog.idle();
      return [
        for (final l in const LineSplitter().convert(await ErrorLog.read()))
          jsonDecode(l) as Map<String, dynamic>,
      ];
    }

    // ZipDecoder devuelve un archivo vacío ante basura o un ZIP truncado: no se
    // distingue de "eligió otro archivo", así que tampoco es un fallo de la app.
    test('un archivo que no es ZIP no se registra', () async {
      await expectLater(
          ImportService.detect(Uint8List.fromList([1, 2, 3, 4])), throwsFormatException);
      expect(await logged(), isEmpty);
    });

    test('un cuaderno con JSON roto queda registrado sin su contenido', () async {
      final bytes = zipWith('notebook.json', '{"title": "Cuaderno secreto", roto');
      final storage = StorageService(baseDir: Directory('${tmp.path}/lib'));
      await expectLater(
        ImportService.importBytes(bytes, storage: storage, extractTo: Directory('${tmp.path}/x')),
        throwsA(anything),
      );
      final entries = await logged();
      expect(entries.single['operation'], 'import.krakink');
      expect(await ErrorLog.read(), isNot(contains('Cuaderno secreto')));
    });

    test('un ZIP que no es de KrakInk no es un fallo de la app', () async {
      await expectLater(
          ImportService.importBytes(zipWith('foo.txt', 'hola')), throwsFormatException);
      expect(await logged(), isEmpty);
    });
  });
}
