// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:io';

import 'app_errors.dart';

/// Largo máximo del mensaje: alcanza para diagnosticar y acota lo que un
/// mensaje inesperado podría arrastrar.
const kMaxErrorMessage = 200;

// Ruta absoluta (Unix o Windows) hasta su último separador. Los segmentos
// admiten espacios porque los nombres de cuaderno los llevan; si eso borra
// texto de más, mejor de más que filtrar un nombre.
final _absoluteDirs = RegExp(
  r'''(?<=^|[\s'"(])(?:[A-Za-z]:)?[\\/](?:[^\\/\n'"]*[\\/])+''',
);

/// Tipo y mensaje de un error sin contenido del usuario, para el registro
/// local que el usuario puede compartir (ver docs/privacy.md).
({String errorType, String message}) sanitizeError(Object error) {
  final errorType = error.runtimeType.toString();
  try {
    final raw = switch (error) {
      // AppError extiende FormatException con mensaje vacío: su código es lo útil.
      AppError() => error.toString(),
      // El toString de FormatException incluye `source`: el texto que no se pudo leer.
      FormatException() => error.message,
      FileSystemException() => [
        error.message,
        if (error.osError != null) error.osError!.message,
      ].join(': '),
      _ => error.toString(),
    };
    final message = raw.replaceAll(_absoluteDirs, '');
    return (
      errorType: errorType,
      message: message.length > kMaxErrorMessage
          ? message.substring(0, kMaxErrorMessage)
          : message,
    );
  } catch (_) {
    return (errorType: errorType, message: '');
  }
}
