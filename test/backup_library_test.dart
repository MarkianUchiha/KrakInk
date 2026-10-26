// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/error_log.dart';
import 'package:inklus/services/storage_service.dart';

void main() {
  late Directory tempDir;
  late StorageService source;
  late StorageService target;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inklus_test_');
    source = StorageService(
      baseDir: Directory('${tempDir.path}/origen')..createSync(),
    );
    target = StorageService(
      baseDir: Directory('${tempDir.path}/destino')..createSync(),
    );
    ErrorLog.fileProvider = () async => File('${tempDir.path}/errors.log');
  });

  tearDown(() async {
    await ErrorLog.idle();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<Map<String, NotebookMeta>> metas(StorageService s) async => {
    for (final m in await s.loadIndex()) m.id: m,
  };

  test('las carpetas viajan en el respaldo', () async {
    final uni = await source.createFolder('Universidad');
    final nb = await source.createNotebook(title: 'Uno', folderId: uni.id);

    await target.importFullBackup(await source.exportFullBackup());

    final lib = await target.loadLibrary();
    expect(lib.folders.single.id, uni.id);
    expect((await metas(target))[nb.id]!.folderId, uni.id);
  });

  test('restaurar fusiona: no se pierden las carpetas propias', () async {
    final mine = await target.createFolder('Mías');
    final inMine = await target.createNotebook(
      title: 'Local',
      folderId: mine.id,
    );
    await target.createFolder('Compartida');
    await source.createFolder('Del respaldo');

    await target.importFullBackup(await source.exportFullBackup());

    final names = (await target.loadLibrary()).folders.map((f) => f.name);
    expect(names, containsAll(['Mías', 'Compartida', 'Del respaldo']));
    expect((await metas(target))[inMine.id]!.folderId, mine.id);
  });

  test('restaurar dos veces no duplica carpetas', () async {
    await source.createFolder('Uni');
    final bytes = await source.exportFullBackup();
    await target.importFullBackup(bytes);
    await target.importFullBackup(bytes);
    expect((await target.loadLibrary()).folders, hasLength(1));
  });

  test(
    'misma carpeta por nombre con otro id: el cuaderno va a la local',
    () async {
      final local = await target.createFolder('Uni');
      final remote = await source.createFolder('uni');
      final nb = await source.createNotebook(title: 'Uno', folderId: remote.id);

      await target.importFullBackup(await source.exportFullBackup());

      expect((await target.loadLibrary()).folders.single.id, local.id);
      expect((await metas(target))[nb.id]!.folderId, local.id);
    },
  );

  test('un cuaderno con carpeta inexistente queda sin carpeta', () async {
    final f = await source.createFolder('Uni');
    final nb = await source.createNotebook(title: 'Uno', folderId: f.id);
    // Respaldo sin library.json (p. ej. de una versión anterior).
    File('${tempDir.path}/origen/library.json').deleteSync();

    await target.importFullBackup(await source.exportFullBackup());

    expect((await metas(target))[nb.id]!.folderId, isNull);
  });
}
