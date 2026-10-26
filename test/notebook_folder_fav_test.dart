// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/notebook.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_test_');
    storage = StorageService(baseDir: tempDir);
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Map<String, dynamic> nbJson(String id) =>
      jsonDecode(File('${tempDir.path}/notebooks/$id.json').readAsStringSync())
          as Map<String, dynamic>;

  Future<NotebookMeta> meta(String id) async =>
      (await storage.loadIndex()).firstWhere((m) => m.id == id);

  group('Notebook: carpeta y favorito', () {
    test('JSON viejo sin las claves carga sin carpeta ni favorito', () {
      final nb = Notebook.fromJson({'id': 'nb_1', 'title': 'Viejo'});
      expect(nb.folderId, isNull);
      expect(nb.favorite, isFalse);
      expect(nb.toJson().containsKey('folder'), isFalse);
      expect(nb.toJson().containsKey('fav'), isFalse);
    });

    test('ida y vuelta por JSON', () {
      final nb = Notebook(
        id: 'nb_1',
        title: 'X',
        folderId: 'f_1',
        favorite: true,
      );
      final back = Notebook.fromJson(nb.toJson());
      expect(back.folderId, 'f_1');
      expect(back.favorite, isTrue);
    });
  });

  group('StorageService: favorito en el cuaderno', () {
    test('setFavorite escribe el archivo del cuaderno y el índice', () async {
      final nb = await storage.createNotebook(title: 'Uno');
      await storage.setFavorite(nb.id, true);
      expect(nbJson(nb.id)['fav'], isTrue);
      expect((await meta(nb.id)).favorite, isTrue);

      await storage.setFavorite(nb.id, false);
      expect(nbJson(nb.id)['fav'], isFalse);
      expect((await meta(nb.id)).favorite, isFalse);
    });

    test('el favorito sobrevive a un índice corrupto', () async {
      final nb = await storage.createNotebook(title: 'Uno');
      await storage.setFavorite(nb.id, true);
      File('${tempDir.path}/index.json').writeAsStringSync('{"formatVers');
      expect((await meta(nb.id)).favorite, isTrue);
    });

    test('el favorito sobrevive a la papelera', () async {
      final nb = await storage.createNotebook(title: 'Uno');
      await storage.setFavorite(nb.id, true);
      await storage.deleteNotebook(nb.id);
      await storage.restoreFromTrash(nb.id);
      expect((await meta(nb.id)).favorite, isTrue);
    });

    test(
      'guardar una copia vieja en memoria no borra favorito ni carpeta',
      () async {
        final nb = await storage.createNotebook(title: 'Uno');
        final stale = (await storage.loadNotebook(nb.id))!;
        await storage.setFavorite(nb.id, true);
        await storage.moveToFolder(nb.id, 'f_1');

        stale.title = 'Editado';
        await storage.saveNotebook(stale);

        final m = await meta(nb.id);
        expect(m.title, 'Editado');
        expect(m.favorite, isTrue);
        expect(m.folderId, 'f_1');
        expect(nbJson(nb.id)['folder'], 'f_1');
      },
    );

    test(
      'un favorito heredado solo en el índice no se pierde al editar',
      () async {
        final nb = await storage.createNotebook(title: 'Uno');
        // Así quedaban los favoritos antes: solo en index.json.
        final indexFile = File('${tempDir.path}/index.json');
        final index = jsonDecode(indexFile.readAsStringSync()) as Map;
        (index['notebooks'] as List).first['fav'] = true;
        indexFile.writeAsStringSync(jsonEncode(index));

        await storage.renameNotebook(nb.id, 'Otro');
        await storage.saveNotebook((await storage.loadNotebook(nb.id))!);
        expect((await meta(nb.id)).favorite, isTrue);
      },
    );
  });

  group('StorageService: carpeta del cuaderno', () {
    test('moveToFolder y sacar de la carpeta', () async {
      final nb = await storage.createNotebook(title: 'Uno');
      await storage.moveToFolder(nb.id, 'f_1');
      expect((await meta(nb.id)).folderId, 'f_1');
      expect((await storage.loadNotebook(nb.id))!.folderId, 'f_1');

      await storage.moveToFolder(nb.id, null);
      expect((await meta(nb.id)).folderId, isNull);
      expect(nbJson(nb.id).containsKey('folder'), isFalse);
    });

    test('createNotebook dentro de una carpeta', () async {
      final nb = await storage.createNotebook(title: 'Uno', folderId: 'f_1');
      expect((await meta(nb.id)).folderId, 'f_1');
    });
  });
}
