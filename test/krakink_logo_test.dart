// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/ui/widgets/krakink_logo.dart';

void main() {
  test('el símbolo ocupa su viewBox', () {
    final b = KrakInkSymbol.path.getBounds();
    // El SVG deja unos px de margen: el path cae dentro y casi lo llena.
    expect(b.left, inInclusiveRange(0, 10));
    expect(b.top, inInclusiveRange(0, 10));
    expect(b.right, inInclusiveRange(1200, 1213));
    expect(b.bottom, inInclusiveRange(1575, 1587));
  });

  test('los ojos son agujeros (even-odd)', () {
    final p = KrakInkSymbol.path;
    expect(p.fillType, PathFillType.evenOdd);
    // Centro del cuerpo: relleno. Aro del ojo izquierdo: hueco.
    expect(p.contains(const Offset(606, 400)), isTrue);
    expect(p.contains(const Offset(355, 815)), isFalse);
  });

  test('el parser acepta L implícito y rechaza comandos desconocidos', () {
    final p = parseSvgPath('M0 0 10 0 10 10Z');
    expect(p.getBounds(), const Rect.fromLTRB(0, 0, 10, 10));
    expect(() => parseSvgPath('M0 0Q1 1 2 2'), throwsFormatException);
  });

  testWidgets('el logo respeta la proporción del símbolo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: KrakInkLogo(size: 40))),
    );
    final size = tester.getSize(find.byType(CustomPaint).last);
    expect(size.height, 40);
    expect(size.width, closeTo(40 * 1213 / 1587, 0.01));
  });
}
