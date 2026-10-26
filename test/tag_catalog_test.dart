// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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

  Future<List<String>> tagsOf(String id) async =>
      (await storage.loadIndex()).firstWhere((m) => m.id == id).tags;

  const base = ['Trabajo', 'Ideas', 'Estudiar'];

  group('Siembra', () {
    test('las base aparecen aunque ningún cuaderno las use', () async {
      await storage.seedTagsOnce(base);
      expect(await storage.allTags(), containsAll(base));
    });

    test('solo una vez: si se borran, no vuelven', () async {
      await storage.seedTagsOnce(base);
      await storage.deleteTag('Ideas');
      await storage.seedTagsOnce(base);
      expect(await storage.allTags(), isNot(contains('Ideas')));
    });

    test('ni en otro idioma después', () async {
      await storage.seedTagsOnce(base);
      await storage.seedTagsOnce(['Work', 'Ideas', 'Study']);
      expect(await storage.allTags(), isNot(contains('Work')));
    });

    test('incluye las etiquetas que ya usaban los cuadernos', () async {
      await storage.createNotebook(title: 'Uno', tags: ['Viejita']);
      await storage.seedTagsOnce(base);
      expect((await storage.loadLibrary()).tags, contains('Viejita'));
    });
  });

  group('Catálogo', () {
    test('una etiqueta puesta a un cuaderno entra al catálogo', () async {
      final nb = await storage.createNotebook(title: 'Uno');
      await storage.setNotebookTags(nb.id, ['Nueva']);
      await storage.setNotebookTags(nb.id, []);
      expect(await storage.allTags(), contains('Nueva'));
    });

    test('renombrar cambia todos los cuadernos y el catálogo', () async {
      await storage.seedTagsOnce(base);
      final a = await storage.createNotebook(title: 'A', tags: ['Ideas']);
      final b = await storage.createNotebook(title: 'B', tags: ['Ideas', 'X']);

      await storage.renameTag('Ideas', 'Proyectos');

      expect(await tagsOf(a.id), ['Proyectos']);
      expect(await tagsOf(b.id), ['Proyectos', 'X']);
      final all = await storage.allTags();
      expect(all, contains('Proyectos'));
      expect(all, isNot(contains('Ideas')));
    });

    test('renombrar a una que ya existe las fusiona sin duplicar', () async {
      final nb = await storage.createNotebook(
        title: 'A',
        tags: ['Ideas', 'Trabajo'],
      );
      await storage.renameTag('Ideas', 'Trabajo');
      expect(await tagsOf(nb.id), ['Trabajo']);
      expect(
        (await storage.allTags()).where((t) => t == 'Trabajo'),
        hasLength(1),
      );
    });

    test('repetir un renombrado converge', () async {
      final nb = await storage.createNotebook(title: 'A', tags: ['Ideas']);
      await storage.renameTag('Ideas', 'Proyectos');
      await storage.renameTag('Ideas', 'Proyectos');
      expect(await tagsOf(nb.id), ['Proyectos']);
    });

    test('borrar la quita de todos los cuadernos, sin borrarlos', () async {
      final a = await storage.createNotebook(title: 'A', tags: ['Ideas', 'X']);
      await storage.deleteTag('Ideas');
      expect(await tagsOf(a.id), ['X']);
      expect(await storage.allTags(), isNot(contains('Ideas')));
      expect(await storage.loadIndex(), hasLength(1));
    });

    test('renombrar a vacío no hace nada', () async {
      final nb = await storage.createNotebook(title: 'A', tags: ['Ideas']);
      await storage.renameTag('Ideas', '  ');
      expect(await tagsOf(nb.id), ['Ideas']);
    });
  });
}
