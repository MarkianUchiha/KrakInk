// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/error_log.dart';

void main() {
  late Directory tmp;
  late File logFile;
  final defaultMaxBytes = ErrorLog.maxBytes;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_errlog_');
    logFile = File('${tmp.path}/errors.log');
    ErrorLog.fileProvider = () async => logFile;
  });

  tearDown(() {
    ErrorLog.maxBytes = defaultMaxBytes;
    tmp.deleteSync(recursive: true);
  });

  List<Map<String, dynamic>> entries(String text) => const LineSplitter()
      .convert(text)
      .where((l) => l.startsWith('{'))
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  test('registra, cuenta y borra', () async {
    await ErrorLog.record(
      StateError('uno'),
      StackTrace.current,
      operation: 'note.save',
    );
    await ErrorLog.record(
      ArgumentError('dos'),
      null,
      operation: 'drive.upload',
      context: 'prueba',
    );
    expect(await ErrorLog.count(), 2);
    final text = await ErrorLog.read();
    expect(text, contains('Bad state: uno'));
    expect(text, contains('prueba'));
    await ErrorLog.clear();
    expect(await ErrorLog.count(), 0);
  });

  test('cada entrada es una línea JSON con los campos fijos', () async {
    await ErrorLog.record(
      StateError('uno'),
      StackTrace.current,
      operation: 'note.save',
      context: 'ctx',
    );
    final e = entries(await ErrorLog.read()).single;
    expect(e['operation'], 'note.save');
    expect(e['result'], 'error');
    expect(e['errorType'], 'StateError');
    expect(e['message'], 'Bad state: uno');
    expect(e['context'], 'ctx');
    expect(e['os'], Platform.operatingSystem);
    expect(e.keys, containsAll(<String>['ts', 'version', 'stack']));
  });

  test('el mensaje va saneado: sin el texto de la nota', () async {
    Object? error;
    try {
      jsonDecode('{"text": "mi nota secreta", roto}');
    } catch (e) {
      error = e;
    }
    await ErrorLog.record(error!, null, operation: 'import.krakink');
    expect(await ErrorLog.read(), isNot(contains('mi nota secreta')));
  });

  test(
    'un registro viejo sigue contando y convive con el formato nuevo',
    () async {
      logFile.writeAsStringSync(
        '=== 2026-10-01 · KrakInk 1.9.0 · android\nBad state: a\n#0 x\n'
        '=== 2026-10-02 · KrakInk 1.9.0 · android\nBad state: b\n\n'
        '=== 2026-10-03 · KrakInk 1.9.0 · android · plataforma\nBad state: c\n',
      );
      expect(await ErrorLog.count(), 3);
      await ErrorLog.record(StateError('d'), null, operation: 'note.save');
      expect(await ErrorLog.count(), 4);
    },
  );

  test('un "=== " dentro de un mensaje no infla el conteo', () async {
    await ErrorLog.record(StateError('a\n=== b'), null, operation: 'note.save');
    expect(await ErrorLog.count(), 1);
  });

  test('no crece sin límite y conserva lo más reciente', () async {
    ErrorLog.maxBytes = 8 * 1024;
    for (var i = 0; i < 120; i++) {
      await ErrorLog.record(
        StateError('error $i ${'x' * 150}'),
        null,
        operation: 'note.save',
      );
    }
    final text = await ErrorLog.read();
    expect(text.length, lessThanOrEqualTo(ErrorLog.maxBytes));
    expect(text, contains('error 119'));
    expect(text, isNot(contains('error 0 ')));
    expect(
      text.startsWith('{'),
      isTrue,
      reason: 'corta por entradas completas',
    );
    expect(entries(text).length, await ErrorLog.count());
  });

  test('FailureStreak registra solo el primer fallo de cada racha', () async {
    final streak = FailureStreak('drive.upload');
    streak.fail(StateError('a'), null);
    streak.fail(StateError('b'), null);
    streak.succeed();
    streak.fail(StateError('c'), null);
    await ErrorLog.idle();
    final logged = entries(await ErrorLog.read());
    expect(logged.map((e) => e['message']), ['Bad state: a', 'Bad state: c']);
    expect(logged.map((e) => e['operation']).toSet(), {'drive.upload'});
  });

  test('un fallo al escribir el registro no lanza', () async {
    ErrorLog.fileProvider = () async =>
        throw const FileSystemException('sin disco');
    await expectLater(
      ErrorLog.record(StateError('x'), null, operation: 'note.save'),
      completes,
    );
  });
}
