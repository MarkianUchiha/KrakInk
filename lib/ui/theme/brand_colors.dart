// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/painting.dart';

/// Colores de la identidad visual de KrakInk. Solo los usa [AppTheme] y los
/// recursos nativos (ícono, splash); los widgets leen `context.colors`.
abstract final class BrandColors {
  /// Texto y fondos oscuros.
  static const tinta = Color(0xFF111318);

  /// Fondo claro y papel.
  static const hueso = Color(0xFFF3EFE6);

  /// Superficies secundarias.
  static const abismo = Color(0xFF1F3A4D);

  /// Acento sobre fondos oscuros (5.04:1 sobre Tinta).
  static const coral = Color(0xFFE4572E);

  /// Coral oscurecido para fondos claros: el coral puro da 3.21:1 sobre
  /// Hueso y no pasa AA como texto; este da 4.83:1.
  static const coralText = Color(0xFFB8401C);

  /// Error en carmín, no en rojo-naranja, para no confundirlo con el coral.
  static const errorLight = Color(0xFFA3133F);
  static const errorDark = Color(0xFFFF8FB8);
}
