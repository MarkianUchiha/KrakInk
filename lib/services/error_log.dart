// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../constants.dart';
import 'app_paths.dart';
import 'error_sanitizer.dart';
import 'file_utils.dart';
import '../brand.dart';

/// Registro **local** de errores: los no capturados y los fallos de las
/// operaciones críticas (guardar, Drive, importar, OCR).
///
/// Sustituye a un servicio de *crash reporting*: nada sale del dispositivo
/// salvo que el usuario comparta el registro a mano (Configuración →
/// "Registro de errores"). Así se puede diagnosticar un fallo sin analítica
/// ni cuentas de terceros.
abstract final class ErrorLog {
  static const _fileName = 'errors.log';

  /// Tamaño máximo: al superarlo se conserva la mitad más reciente.
  /// Variable solo para que los tests no tengan que escribir 256 KB.
  @visibleForTesting
  static int maxBytes = 256 * 1024;

  static final SerialQueue _queue = SerialQueue();

  /// Archivo del registro (null en tests, donde se puede sustituir).
  @visibleForTesting
  static Future<File> Function() fileProvider = () => AppPaths.file(_fileName);

  /// Añade un error con su traza, como una línea JSON. Nunca lanza: un fallo
  /// al registrar no debe provocar otro.
  ///
  /// [operation] es obligatorio para que cada sitio que registra diga qué
  /// falló (`note.save`, `drive.upload`…) y el registro se pueda filtrar.
  static Future<void> record(
    Object error,
    StackTrace? stack, {
    required String operation,
  }) {
    final clean = sanitizeError(error);
    final entry = jsonEncode({
      'ts': DateTime.now().toIso8601String(),
      'app': Brand.appName,
      'version': kAppVersion,
      'os': Platform.operatingSystem,
      'operation': operation,
      'result': 'error',
      'errorType': clean.errorType,
      'message': clean.message,
      'stack': _trim(stack),
    });
    return _queue.run(() async {
      try {
        final file = await fileProvider();
        var text = await file.exists() ? await file.readAsString() : '';
        text += '$entry\n';
        if (text.length > maxBytes) {
          // Corta por el inicio de una entrada para no dejar trazas a medias.
          final cut = _nextEntryStart(text, text.length - maxBytes ~/ 2);
          text = cut < 0
              ? text.substring(text.length - maxBytes ~/ 2)
              : text.substring(cut);
        }
        await writeAtomic(file, text);
      } catch (e) {
        debugPrint('ErrorLog.record: $e');
      }
    });
  }

  /// Termina cuando se escribió todo lo registrado hasta ahora. Los sitios
  /// que registran no esperan (`unawaited`); los tests sí necesitan hacerlo,
  /// y un `Future.delayed` fijo falla con la suite en paralelo.
  @visibleForTesting
  static Future<void> idle() => _queue.run(() async {});

  /// Contenido completo ('' si no hay errores).
  static Future<String> read() async {
    final file = await fileProvider();
    return await file.exists() ? file.readAsString() : '';
  }

  /// Número de errores registrados, sumando las entradas en texto de
  /// versiones anteriores (`=== …`) para no perderlas al actualizar.
  static Future<int> count() async => const LineSplitter()
      .convert(await read())
      .where((l) => _isEntryStart(l))
      .length;

  // Las entradas nuevas empiezan con '{"ts"' y las viejas con '=== '. Un
  // "=== " dentro de un mensaje no cuenta: JSON escapa el salto de línea.
  static bool _isEntryStart(String text, [int at = 0]) =>
      text.startsWith('{"ts"', at) || text.startsWith('=== ', at);

  static int _nextEntryStart(String text, int from) {
    var i = text.indexOf('\n', from);
    while (i >= 0 && !_isEntryStart(text, i + 1)) {
      i = text.indexOf('\n', i + 1);
    }
    return i < 0 ? -1 : i + 1;
  }

  static Future<void> clear() => _queue.run(() async {
    final file = await fileProvider();
    if (await file.exists()) await file.delete();
  });

  /// Primeras líneas de la traza (lo útil para diagnosticar).
  static String _trim(StackTrace? stack) {
    if (stack == null) return '';
    final lines = stack.toString().split('\n');
    return lines.take(25).join('\n');
  }
}

/// Registra solo el primer fallo de una racha. Una operación que se reintenta
/// sola (sync con Drive) llenaría el registro con el mismo error y borraría lo
/// útil al recortar. Un error de otro tipo cuenta como racha nueva: es otra
/// causa y no debe perderse.
class FailureStreak {
  FailureStreak(this.operation);

  final String operation;
  Type? _lastType;

  void fail(Object error, StackTrace? stack) {
    if (error.runtimeType == _lastType) return;
    _lastType = error.runtimeType;
    unawaited(ErrorLog.record(error, stack, operation: operation));
  }

  void succeed() => _lastType = null;
}
