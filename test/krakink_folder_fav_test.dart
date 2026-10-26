// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/import_service.dart';
import 'package:inklus/services/inklus_format.dart';
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

  Future<Uint8List> export(String id) async {
    final e = (await storage.notebookForExport(id))!;
    return InklusFormat.exportNotebookBytes(
      e.notebook,
      folderName: e.folderName,
    );
  }

  Future<NotebookMeta> import(Uint8List bytes, StorageService into) async {
    final r = await ImportService.importBytes(
      bytes,
      storage: into,
      extractTo: Directory('${tempDir.path}/extract'),
    );
    return (await into.loadIndex()).firstWhere((m) => m.id == r.notebookId);
  }

  Map<String, dynamic> notebookEntry(Uint8List bytes) {
    final f = ZipDecoder().decodeBytes(bytes).findFile('notebook.json')!;
    return jsonDecode(utf8.decode(f.readBytes()!)) as Map<String, dynamic>;
  }

  test('favorito y carpeta sobreviven a exportar, borrar e importar', () async {
    final folder = await storage.createFolder('Universidad');
    final nb = await storage.createNotebook(title: 'Uno', folderId: folder.id);
    await storage.setFavorite(nb.id, true);
    final bytes = await export(nb.id);

    await storage.deleteNotebook(nb.id);
    final meta = await import(bytes, storage);

    expect(meta.favorite, isTrue);
    expect(meta.folderId, folder.id);
  });

  test('en otro dispositivo la carpeta se crea por nombre', () async {
    final folder = await storage.createFolder('Universidad');
    final nb = await storage.createNotebook(title: 'Uno', folderId: folder.id);
    final bytes = await export(nb.id);

    final otherDir = Directory('${tempDir.path}/otro')..createSync();
    final other = StorageService(baseDir: otherDir);
    final meta = await import(bytes, other);

    final created = (await other.loadLibrary()).folderNamed('Universidad');
    expect(created, isNotNull);
    expect(meta.folderId, created!.id);
  });

  test(
    'si el cuaderno ya existe, se conservan favorito y carpeta locales',
    () async {
      final a = await storage.createFolder('A');
      final b = await storage.createFolder('B');
      final nb = await storage.createNotebook(title: 'Uno', folderId: a.id);
      await storage.setFavorite(nb.id, true);
      final bytes = await export(nb.id);

      await storage.setFavorite(nb.id, false);
      await storage.moveToFolder(nb.id, b.id);
      final meta = await import(bytes, storage);

      expect(meta.favorite, isFalse);
      expect(meta.folderId, b.id);
    },
  );

  test('un favorito heredado solo en el índice también se exporta', () async {
    final nb = await storage.createNotebook(title: 'Uno');
    final indexFile = File('${tempDir.path}/index.json');
    final index = jsonDecode(indexFile.readAsStringSync()) as Map;
    (index['notebooks'] as List).first['fav'] = true;
    indexFile.writeAsStringSync(jsonEncode(index));

    expect(notebookEntry(await export(nb.id))['fav'], isTrue);
  });

  test('sin carpeta ni favorito no se escriben las claves', () async {
    final nb = await storage.createNotebook(title: 'Uno');
    final entry = notebookEntry(await export(nb.id));
    expect(entry.containsKey('fav'), isFalse);
    expect(entry.containsKey('folderName'), isFalse);
  });
}
