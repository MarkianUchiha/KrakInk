// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/foundation.dart';

import 'error_log.dart';

/// Conecta los errores del framework y del motor al registro local. Vive
/// fuera de `main.dart` para poder probarlo sin arrancar la app.
void installErrorHandlers() {
  // Errores de framework: reporte por defecto (pantalla roja en debug, log en
  // release) + registro local (ver ErrorLog; nunca sale del dispositivo salvo
  // que el usuario lo comparta).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // Sin `details.context`: describe el widget que se construía y puede
    // traer su texto (título de nota, resultado de OCR).
    ErrorLog.record(
      details.exception,
      details.stack,
      operation: 'uncaught.flutter',
    );
  };
  // Errores asíncronos del motor/plugins.
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.record(error, stack, operation: 'uncaught.platform');
    return true;
  };
}

/// Handler de `runZonedGuarded`: lo que escapó a los otros dos.
void recordZoneError(Object error, StackTrace stack) {
  debugPrint('Uncaught exception: $error');
  debugPrintStack(stackTrace: stack);
  ErrorLog.record(error, stack, operation: 'uncaught.zone');
}
