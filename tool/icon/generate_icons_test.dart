// SPDX-License-Identifier: GPL-3.0-or-later
// Genera los PNG del ícono desde el mismo path que KrakInkLogo:
//
//   flutter test tool/icon/generate_icons_test.dart
//
// - android/app/src/main/res/mipmap-*/ic_launcher.png: ícono legacy para
//   Android 7 (API 24–25). Desde Android 8 manda el adaptativo vectorial
//   (mipmap-anydpi-v26), que no necesita PNG.
// - assets/brand/play-icon-512.png: ícono de la ficha de Play (Play le
//   aplica la máscara, por eso va a sangre).
//
// Está fuera de test/ a propósito: escribe en el repo y no es parte de la CI.
// Se vuelve a correr solo si cambia el símbolo o sus colores.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/ui/theme/brand_colors.dart';
import 'package:inklus/ui/widgets/krakink_logo.dart';

/// Dibuja el calamar en Hueso sobre Tinta.
///
/// [inset] es el margen alrededor del fondo y [symbolHeight] el alto del
/// símbolo, ambos como fracción del lado.
Future<List<int>> _render(
  int side, {
  required double inset,
  required double radius,
  required double symbolHeight,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = side.toDouble();
  final bg = Rect.fromLTWH(
    s * inset,
    s * inset,
    s * (1 - 2 * inset),
    s * (1 - 2 * inset),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(bg, Radius.circular(s * radius)),
    Paint()..color = BrandColors.tinta,
  );

  final h = s * symbolHeight;
  final scale = h / KrakInkSymbol.viewBox.height;
  final w = KrakInkSymbol.viewBox.width * scale;
  canvas
    ..translate((s - w) / 2, (s - h) / 2)
    ..scale(scale)
    ..drawPath(KrakInkSymbol.path, Paint()..color = BrandColors.hueso);

  final image = await recorder.endRecording().toImage(side, side);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('genera los PNG del ícono', (tester) async {
    await tester.runAsync(() async {
      const legacy = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };
      for (final MapEntry(key: density, value: side) in legacy.entries) {
        // Keylines de Material para íconos legacy: cuadrado de 44 en 48.
        final png = await _render(
          side,
          inset: 2 / 48,
          radius: 0.2,
          symbolHeight: 0.66,
        );
        File(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        ).writeAsBytesSync(png);
      }
      final play = await _render(512, inset: 0, radius: 0, symbolHeight: 0.6);
      File('assets/brand/play-icon-512.png').writeAsBytesSync(play);
    });
  });
}
