// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/error_handlers.dart';
import 'package:inklus/services/error_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('inklus_handlers_');
    ErrorLog.fileProvider = () async => File('${tmp.path}/errors.log');
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  Future<String> lastOperation() async {
    await ErrorLog.idle();
    final lines = const LineSplitter().convert(await ErrorLog.read());
    return (jsonDecode(lines.last) as Map<String, dynamic>)['operation']
        as String;
  }

  test('cada handler registra con su operación', () async {
    final flutterOnError = FlutterError.onError;
    final platformOnError = PlatformDispatcher.instance.onError;
    final presentError = FlutterError.presentError;
    addTearDown(() {
      FlutterError.onError = flutterOnError;
      PlatformDispatcher.instance.onError = platformOnError;
      FlutterError.presentError = presentError;
    });
    // Sin esto el test imprime el error como si fallara.
    FlutterError.presentError = (_) {};

    installErrorHandlers();

    // El contexto describe el widget que se construía, con su texto.
    FlutterError.onError!(
      FlutterErrorDetails(
        exception: StateError('framework'),
        context: ErrorDescription('while building Text("diario intimo")'),
      ),
    );
    expect(await lastOperation(), 'uncaught.flutter');
    expect(await ErrorLog.read(), isNot(contains('diario intimo')));

    expect(
      PlatformDispatcher.instance.onError!(
        StateError('motor'),
        StackTrace.empty,
      ),
      isTrue,
    );
    expect(await lastOperation(), 'uncaught.platform');

    recordZoneError(StateError('zona'), StackTrace.empty);
    expect(await lastOperation(), 'uncaught.zone');
  });
}
