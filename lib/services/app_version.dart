// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';

import 'package:package_info_plus/package_info_plus.dart';

import 'error_log.dart';

/// Versión de la app instalada, leída del paquete: `pubspec.yaml` es la única
/// fuente y un build con `--build-name` reporta lo que de verdad se instaló.
///
/// Se lee una vez en `main()` y queda disponible de forma síncrona, porque el
/// registro de errores no puede esperar a un canal de plataforma.
abstract final class AppVersion {
  /// Lo que se muestra si no se pudo leer: mejor un `?` visible en Ajustes y
  /// en el registro que un número inventado.
  static const fallback = '?';

  static String _current = fallback;

  static String get current => _current;

  /// Nunca lanza: si la lectura falla la app arranca igual y queda registrado.
  static Future<void> load({
    Future<PackageInfo> Function() read = PackageInfo.fromPlatform,
  }) async {
    try {
      final version = (await read()).version;
      if (version.isEmpty) throw StateError('versionName vacío');
      _current = version;
    } catch (e, s) {
      _current = fallback;
      unawaited(ErrorLog.record(e, s, operation: 'app.version'));
    }
  }
}
