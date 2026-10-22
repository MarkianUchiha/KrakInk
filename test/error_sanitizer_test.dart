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

  test('las rutas absolutas se quitan enteras, nombre de archivo incluido', () {
    // El nombre de archivo también es del usuario: título de nota, PDF elegido.
    final r = sanitizeError(
      StateError(
        "Cannot open '/storage/emulated/0/Download/Diagnóstico de Ana.pdf'",
      ),
    );
    expect(r.message, contains('Cannot open'));
    expect(r.message, isNot(contains('Ana')));
    expect(r.message, isNot(contains('Download')));
    final w = sanitizeError(
      StateError(r'falta C:\Users\ana\krakink\Privado\abc.json'),
    );
    expect(w.message, contains('falta'));
    expect(w.message, isNot(contains('Privado')));
    expect(w.message, isNot(contains('abc.json')));
  });

  test('las rutas tras = o : y las URI file:// también se quitan', () {
    for (final raw in [
      'path=/data/user/0/app/notebooks/Cuaderno secreto/x.png',
      'Invalid argument(s): file:///storage/emulated/0/Notas privadas/a.pdf',
      'error:/data/user/0/app/Mis notas/b.json',
    ]) {
      final m = sanitizeError(ArgumentError(raw)).message;
      expect(m, isNot(contains('secreto')), reason: raw);
      expect(m, isNot(contains('privadas')), reason: raw);
      expect(m, isNot(contains('Mis notas')), reason: raw);
    }
  });

  test('las fracciones y palabras con barra no son rutas', () {
    expect(
      sanitizeError(StateError('página 1/2 y/o')).message,
      'Bad state: página 1/2 y/o',
    );
  });

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
