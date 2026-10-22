// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/models/stroke.dart';
import 'package:inklus/logic/canvas_controller.dart';
import 'package:inklus/models/note.dart';
import 'package:inklus/services/error_log.dart';
import 'package:inklus/services/storage_service.dart';

/// Almacenamiento cuyo guardado falla mientras [failing] sea true.
class _FlakyStorage extends StorageService {
  _FlakyStorage(Directory dir) : super(baseDir: dir);
  bool failing = true;
  int saves = 0;
  FileSystemException error = const FileSystemException('disco lleno');

  @override
  Future<void> saveNote(String notebookId, Note note, {bool touch = true}) async {
    if (failing) throw error;
    saves++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late _FlakyStorage storage;
  late CanvasController c;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_save_');
    ErrorLog.fileProvider = () async => File('${tmp.path}/errors.log');
    storage = _FlakyStorage(tmp);
    c = CanvasController(storage, notebookId: 'nb')..setHapticEnabled(false);
  });

  tearDown(() {
    c.dispose();
    tmp.deleteSync(recursive: true);
  });

  void scribble() {
    c.beginStroke(const Offset(0, 0), 0.5, tool: ToolType.pen);
    c.addStrokePoint(const Offset(20, 0), 0.5);
    c.endStroke();
  }

  test('un guardado fallido avisa una sola vez, se registra y se reintenta', () async {
    var avisos = 0;
    c.onSaveError = (_) => avisos++;
    scribble();
    await c.saveNow();
    await c.saveNow(); // segundo fallo de la misma racha: sin aviso nuevo
    expect(avisos, 1);
    // El registro se escribe en segundo plano.
    await ErrorLog.idle();
    expect(await ErrorLog.count(), 1);

    storage.failing = false;
    await c.saveNow(); // lo pendiente sigue marcado: se guarda
    expect(storage.saves, 1);

    storage.failing = true;
    scribble();
    await c.saveNow(); // nueva racha tras un éxito: vuelve a avisar
    expect(avisos, 2);
  });

  test('OBS-02: el fallo de guardado queda como note.save y sin la ruta', () async {
    storage.error = const FileSystemException(
        'disco lleno', '/data/user/0/app/krakink/Cuaderno privado/n1.json');
    scribble();
    await c.saveNow();
    await ErrorLog.idle();
    final entry = jsonDecode((await ErrorLog.read()).trim()) as Map<String, dynamic>;
    expect(entry['operation'], 'note.save');
    expect(entry['errorType'], 'FileSystemException');
    expect(entry['message'], contains('disco lleno'));
    expect(jsonEncode(entry), isNot(contains('Cuaderno privado')));
  });

  test('Note guarda schemaVersion y abre notas sin ese campo', () {
    final note = Note.newBlank(id: 'n1');
    final json = note.toJson();
    expect(json['schemaVersion'], Note.currentSchema);
    expect(Note.fromJson(json).toJson(), json);

    final legacy = Map<String, dynamic>.from(json)..remove('schemaVersion');
    expect(Note.fromJson(legacy).id, 'n1');
  });
}
