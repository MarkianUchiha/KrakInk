// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/app_version.dart';
import 'package:inklus/services/error_log.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  late Directory tmp;
  late File logFile;

  void mockVersion(String version) => PackageInfo.setMockInitialValues(
    appName: 'KrakInk',
    packageName: 'com.markidev.krakink',
    version: version,
    buildNumber: '1',
    buildSignature: '',
  );

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('krakink_version_');
    logFile = File('${tmp.path}/errors.log');
    ErrorLog.fileProvider = () async => logFile;
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test('reporta la versión del paquete instalado', () async {
    mockVersion('9.8.7');
    await AppVersion.load();
    expect(AppVersion.current, '9.8.7');
  });

  test('si la lectura falla, usa el respaldo y lo registra', () async {
    await AppVersion.load(read: () async => throw StateError('sin canal'));
    expect(AppVersion.current, AppVersion.fallback);
    await ErrorLog.idle();
    expect(await ErrorLog.read(), contains('"operation":"app.version"'));
  });

  test('una versión vacía cuenta como falla', () async {
    mockVersion('');
    await AppVersion.load();
    expect(AppVersion.current, AppVersion.fallback);
  });

  test('el registro de errores lleva la versión leída', () async {
    mockVersion('9.8.7');
    await AppVersion.load();
    await ErrorLog.record(StateError('x'), null, operation: 'note.save');
    final entry = jsonDecode(LineSplitter.split(await ErrorLog.read()).last);
    expect(entry['version'], '9.8.7');
  });
}
