// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/library_data.dart';
import 'package:inklus/services/error_log.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_test_');
    storage = StorageService(baseDir: tempDir);
    ErrorLog.fileProvider = () async => File('${tempDir.path}/errors.log');
  });

  tearDown(() async {
    await ErrorLog.idle();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<List<Folder>> folders() async => (await storage.loadLibrary()).folders;

  group('LibraryData', () {
    test('JSON vacío o con claves faltantes carga vacío', () {
      final lib = LibraryData.fromJson({});
      expect(lib.folders, isEmpty);
      expect(lib.tags, isEmpty);
      expect(lib.tagsSeeded, isFalse);
    });

    test('ida y vuelta por JSON', () {
      final lib = LibraryData(
        folders: [Folder(id: 'f_1', name: 'Uni', createdAt: DateTime(2026))],
        tags: ['Ideas'],
        tagsSeeded: true,
      );
      final back = LibraryData.fromJson(lib.toJson());
      expect(back.folders.single.name, 'Uni');
      expect(back.folders.single.createdAt, DateTime(2026));
      expect(back.tags, ['Ideas']);
      expect(back.tagsSeeded, isTrue);
    });
  });

  group('Carpetas', () {
    test('crear persiste en library.json', () async {
      final f = await storage.createFolder('  Universidad ');
      expect(f.name, 'Universidad');
      final again = StorageService(baseDir: tempDir);
      expect((await again.loadLibrary()).folders.single.id, f.id);
    });

    test(
      'crear con un nombre que ya existe devuelve la misma carpeta',
      () async {
        final a = await storage.createFolder('Trabajo');
        final b = await storage.createFolder('trabajo ');
        expect(b.id, a.id);
        expect(await folders(), hasLength(1));
      },
    );

    test('nombre vacío no se acepta', () async {
      expect(() => storage.createFolder('  '), throwsArgumentError);
    });

    test('renombrar, y no a un nombre que ya usa otra carpeta', () async {
      final a = await storage.createFolder('A');
      await storage.createFolder('B');
      expect(await storage.renameFolder(a.id, 'C'), isTrue);
      expect(await storage.renameFolder(a.id, 'b'), isFalse);
      expect((await folders()).map((f) => f.name), containsAll(['C', 'B']));
    });

    test('borrar deja sus cuadernos sin carpeta y no los borra', () async {
      final a = await storage.createFolder('A');
      final b = await storage.createFolder('B');
      final inA = await storage.createNotebook(title: '1', folderId: a.id);
      final inB = await storage.createNotebook(title: '2', folderId: b.id);

      await storage.deleteFolder(a.id);

      final metas = {for (final m in await storage.loadIndex()) m.id: m};
      expect(metas.keys, containsAll([inA.id, inB.id]));
      expect(metas[inA.id]!.folderId, isNull);
      expect(metas[inB.id]!.folderId, b.id);
      expect((await folders()).map((f) => f.id), [b.id]);
    });

    test('crear en paralelo no pierde carpetas', () async {
      await Future.wait(List.generate(8, (i) => storage.createFolder('C$i')));
      expect(await folders(), hasLength(8));
    });

    test(
      'library.json corrupto se aparta y la biblioteca arranca vacía',
      () async {
        File('${tempDir.path}/library.json').writeAsStringSync('{"folders');
        expect(await folders(), isEmpty);
        expect(
          tempDir.listSync().where(
            (e) => e.path.contains('library.json.corrupt'),
          ),
          hasLength(1),
        );
      },
    );
  });

  group('OBS-01: fallos de carpetas en el registro', () {
    test('mover un cuaderno falla y queda folder.move sin nombres', () async {
      final nb = await storage.createNotebook(title: 'Secreto');
      // JSON truncado: la edición falla al leerlo.
      File('${tempDir.path}/notebooks/${nb.id}.json')
          .writeAsStringSync('{"title": "Secreto"');

      await expectLater(storage.moveToFolder(nb.id, 'f_1'), throwsA(anything));
      await ErrorLog.idle();
      final log = await ErrorLog.read();
      expect(log, contains('"operation":"folder.move"'));
      expect(log, isNot(contains('Secreto')));
    });

    test('library.json corrupto queda como library.read', () async {
      File('${tempDir.path}/library.json').writeAsStringSync('{"folders');
      await storage.loadLibrary();
      await ErrorLog.idle();
      expect(await ErrorLog.read(), contains('"operation":"library.read"'));
    });
  });
}
