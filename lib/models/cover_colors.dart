// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:ui';

/// Paleta de tapas de cuaderno (identidad visual de KrakInk).
///
/// Vive en `models/` y no en `ui/` porque estos valores ARGB se guardan
/// tal cual en el índice: cambiarlos es cambiar datos, no solo estilo.
abstract final class CoverColors {
  static const tinta = Color(0xFF111318);
  static const abismo = Color(0xFF1F3A4D);
  static const coral = Color(0xFFE4572E);
  static const hueso = Color(0xFFF3EFE6);
  static const piedra = Color(0xFFB8AE9C);
  static const marea = Color(0xFF2F6F6A);
  static const musgo = Color(0xFF4A5D3A);
  static const ocre = Color(0xFFC8963E);
  static const vino = Color(0xFF6E2A35);
  static const ciruela = Color(0xFF5B4A6B);

  /// Orden del selector. Añadir al final: el orden lo ven los usuarios.
  static const all = [
    tinta,
    abismo,
    coral,
    hueso,
    piedra,
    marea,
    musgo,
    ocre,
    vino,
    ciruela,
  ];

  /// Texto legible sobre [c]: Tinta o Hueso, el de más contraste.
  ///
  /// Se calcula en vez de listar los colores claros para que también
  /// funcione con "Sin color" (usa el primario del tema) y con colores
  /// guardados que ya no están en la paleta.
  static Color textOn(Color c) {
    final l = c.computeLuminance();
    final vsTinta = (l + 0.05) / (tinta.computeLuminance() + 0.05);
    final vsHueso = (hueso.computeLuminance() + 0.05) / (l + 0.05);
    return vsTinta >= vsHueso ? tinta : hueso;
  }

  /// Paleta de Inklus (hasta 1.9.0) → equivalente más cercano de la nueva.
  static final Map<int, int> _legacy = {
    0xFF3B82F6: abismo.toARGB32(), // azul
    0xFF4CAF50: musgo.toARGB32(), // verde
    0xFFE53935: vino.toARGB32(), // rojo
    0xFFFF9800: ocre.toARGB32(), // naranja
    0xFF9C27B0: ciruela.toARGB32(), // morado
    0xFFEC407A: coral.toARGB32(), // rosa
    0xFF26C6DA: marea.toARGB32(), // turquesa
    0xFF78909C: piedra.toARGB32(), // gris
  };

  /// Traduce un color de la paleta vieja; cualquier otro valor pasa igual.
  ///
  /// Se aplica al leer (`fromJson`) en vez de reescribir el índice: es
  /// idempotente, cubre copias de Drive y respaldos viejos, y el valor
  /// nuevo queda en disco con el siguiente guardado.
  static int? migrateLegacy(int? value) => _legacy[value] ?? value;
}
