// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/app_errors.dart';
import 'package:inklus/services/error_sanitizer.dart';

class _ThrowingToString {
  @override
  String toString() => throw StateError('boom');
}

void main() {
  test('FormatException de jsonDecode no deja el contenido de la nota', () {
    Object? error;
    try {
      jsonDecode('{"text": "mi nota secreta", roto}');
    } catch (e) {
      error = e;
    }
    final r = sanitizeError(error!);
    expect(r.errorType, 'FormatException');
    expect(r.message, isNot(contains('mi nota secreta')));
    expect(r.message, contains('Unexpected character'));
  });

  test('FileSystemException no deja la ruta absoluta', () {
    final r = sanitizeError(
      const FileSystemException(
        'Cannot open file',
        '/data/user/0/app/krakink/Cuaderno de Ana/nota.json',
        OSError('No such file or directory', 2),
      ),
    );
    expect(r.errorType, 'FileSystemException');
    expect(r.message, contains('Cannot open file'));
    expect(r.message, contains('No such file or directory'));
    expect(r.message, isNot(contains('Cuaderno de Ana')));
    expect(r.message, isNot(contains('/data/user')));
  });

  test(
    'las rutas absolutas en otros errores se reducen al nombre de archivo',
    () {
      final r = sanitizeError(
        StateError('falta /data/user/0/app/krakink/Mis notas/abc.json'),
      );
      expect(r.message, contains('abc.json'));
      expect(r.message, isNot(contains('Mis notas')));
      final w = sanitizeError(
        StateError(r'falta C:\Users\ana\krakink\Privado\abc.json'),
      );
      expect(w.message, contains('abc.json'));
      expect(w.message, isNot(contains('Privado')));
    },
  );

  test('AppError conserva su código, que no lleva contenido', () {
    final r = sanitizeError(const AppError(AppErrorCode.notInklus));
    expect(r.errorType, 'AppError');
    expect(r.message, contains('notInklus'));
  });

  test('el mensaje se recorta a 200 caracteres', () {
    final r = sanitizeError(StateError('x' * 1000));
    expect(r.message.length, lessThanOrEqualTo(200));
  });

  test('un toString que lanza deja solo el tipo', () {
    final r = sanitizeError(_ThrowingToString());
    expect(r.errorType, '_ThrowingToString');
    expect(r.message, '');
  });
}
