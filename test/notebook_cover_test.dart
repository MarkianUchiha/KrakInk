// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late Directory outside;
  late StorageService storage;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_test_');
    outside = Directory.systemTemp.createTempSync('inklus_picker_');
    storage = StorageService(baseDir: tempDir);
  });

  tearDown(() {
    for (final d in [tempDir, outside]) {
      if (d.existsSync()) d.deleteSync(recursive: true);
    }
  });

  Map<String, dynamic> nbJson(String id) =>
      jsonDecode(File('${tempDir.path}/notebooks/$id.json').readAsStringSync())
          as Map<String, dynamic>;

  /// Imagen elegida con el selector: vive fuera de la carpeta de datos.
  File pickedImage() =>
      File('${outside.path}/foto.png')..writeAsBytesSync([1, 2, 3]);

  group('Portada con imagen', () {
    test('al crear se copia a covers/ y se guarda relativa', () async {
      final picked = pickedImage();
      final nb = await storage.createNotebook(
        title: 'Uno',
        coverStyle: 'custom',
        coverImagePath: picked.path,
      );
      picked.deleteSync(); // la caché del selector se limpió

      final meta = (await storage.loadIndex()).single;
      expect(File(meta.coverImagePath!).readAsBytesSync(), [1, 2, 3]);
      expect(nbJson(nb.id)['coverImagePath'], startsWith('covers/'));
      final loaded = await storage.loadNotebook(nb.id);
      expect(File(loaded!.coverImagePath!).existsSync(), isTrue);
    });

    test('una portada vieja con ruta absoluta sigue cargando', () async {
      final picked = pickedImage();
      final nb = await storage.createNotebook(title: 'Uno');
      final json = nbJson(nb.id)
        ..['coverStyle'] = 'custom'
        ..['coverImagePath'] = picked.path;
      File('${tempDir.path}/notebooks/${nb.id}.json')
          .writeAsStringSync(jsonEncode(json));

      final loaded = await storage.loadNotebook(nb.id);
      expect(loaded!.coverImagePath, picked.path);
    });
  });

  group('Limpieza de portadas', () {
    test('se borra al salir de la papelera, no antes', () async {
      final nb = await storage.createNotebook(
        title: 'Uno',
        coverStyle: 'custom',
        coverImagePath: pickedImage().path,
      );
      final cover = File((await storage.loadIndex()).single.coverImagePath!);

      await storage.deleteNotebook(nb.id);
      await storage.collectOrphanedImages();
      expect(cover.existsSync(), isTrue, reason: 'aún se puede restaurar');

      File('${tempDir.path}/trash/${nb.id}.json').deleteSync();
      await storage.collectOrphanedImages();
      expect(cover.existsSync(), isFalse);
    });
  });

  group('Duplicar', () {
    test('conserva portada y carpeta, sin favorito', () async {
      final nb = await storage.createNotebook(
        title: 'Uno',
        coverStyle: 'custom',
        coverImagePath: pickedImage().path,
        folderId: 'f_1',
      );
      await storage.setFavorite(nb.id, true);

      final copy = await storage.duplicateNotebook(nb.id);
      final meta = (await storage.loadIndex()).firstWhere(
        (m) => m.id == copy.id,
      );
      final original = (await storage.loadIndex()).firstWhere(
        (m) => m.id == nb.id,
      );

      expect(meta.coverStyle, 'custom');
      expect(meta.folderId, 'f_1');
      expect(meta.favorite, isFalse);
      expect(
        meta.coverImagePath,
        isNot(original.coverImagePath),
        reason: 'archivo propio: borrar uno no deja sin portada al otro',
      );
      expect(File(meta.coverImagePath!).readAsBytesSync(), [1, 2, 3]);
    });

    test('conserva un estilo sin imagen', () async {
      final nb = await storage.createNotebook(
        title: 'Uno',
        coverStyle: 'waves',
      );
      final copy = await storage.duplicateNotebook(nb.id);
      expect((await storage.loadNotebook(copy.id))!.coverStyle, 'waves');
    });
  });
}
