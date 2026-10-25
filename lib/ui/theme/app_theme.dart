// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter/material.dart';

import 'brand_colors.dart';
import 'inklus_colors.dart';
import 'tokens.dart';

/// Construye los [ThemeData] de Inklus (claro y oscuro).
///
/// Reglas:
/// - Todo color de interfaz sale de `Theme.of(context).colorScheme` o de
///   [InklusColors] (`context.inklus`). Nada de `Colors.white`/`Color(0x…)`
///   sueltos en los widgets.
/// - La escala tipográfica está pensada para tablet (nada por debajo de
///   12 pt; texto de interfaz habitual 14–16 pt).
/// - Los componentes (diálogos, hojas, snackbars, sliders…) se configuran
///   aquí una vez, no en cada pantalla.
abstract final class AppTheme {
  /// Abismo aclarado: secundario legible sobre Tinta en modo oscuro.
  static const Color _abismoLight = Color(0xFF9DB8CC);

  /// Abismo muy claro: contenedor secundario sobre Hueso.
  static const Color _abismoPale = Color(0xFFD5E0E8);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final extra = isDark ? InklusColors.dark : InklusColors.light;
    // fromSeed solo aporta los tonos derivados (contenedores, outline…);
    // los roles que define la identidad se fijan a mano, porque fromSeed
    // los aproxima y no respeta los contrastes que pide la marca.
    final scheme = ColorScheme.fromSeed(
      seedColor: BrandColors.coral,
      brightness: brightness,
      // fidelity: respeta el tono de la marca (tonalSpot lo desatura).
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    ).copyWith(
      // En claro el coral puro no pasa AA como texto: se usa el oscurecido.
      primary: isDark ? BrandColors.coral : BrandColors.coralText,
      onPrimary: isDark ? BrandColors.tinta : BrandColors.hueso,
      secondary: isDark ? _abismoLight : BrandColors.abismo,
      onSecondary: isDark ? BrandColors.tinta : BrandColors.hueso,
      secondaryContainer: isDark ? BrandColors.abismo : _abismoPale,
      onSecondaryContainer: isDark ? BrandColors.hueso : BrandColors.abismo,
      surface: isDark ? BrandColors.tinta : BrandColors.hueso,
      onSurface: isDark ? BrandColors.hueso : BrandColors.tinta,
      // Neutros escalonados desde Hueso/Tinta: los de fromSeed salen
      // teñidos de coral (barras y campos se veían rosados).
      surfaceContainerLowest: isDark ? const Color(0xFF0C0E12) : const Color(0xFFFBF9F4),
      surfaceContainerLow: isDark ? const Color(0xFF181B21) : const Color(0xFFEFEBE2),
      surfaceContainer: isDark ? const Color(0xFF1C1F26) : const Color(0xFFEAE5DB),
      surfaceContainerHigh: isDark ? const Color(0xFF23272F) : const Color(0xFFE4DFD4),
      surfaceContainerHighest: isDark ? const Color(0xFF2B2F38) : const Color(0xFFDDD7CB),
      onSurfaceVariant: isDark ? const Color(0xFFC9C3B8) : const Color(0xFF4A4740),
      error: extra.danger,
      onError: isDark ? BrandColors.tinta : BrandColors.hueso,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [extra],
    );

    final text = _textTheme(base.textTheme, scheme);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: Radii.xlAll),
        titleTextStyle: text.titleLarge,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        width: 520,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        textStyle: text.labelMedium?.copyWith(color: scheme.onInverseSurface),
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: Radii.smAll,
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: const OutlineInputBorder(
          borderRadius: Radii.mdAll,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        textStyle: text.bodyLarge,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(Sizes.minTouch),
          shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        shape: const RoundedRectangleBorder(borderRadius: Radii.lgAll),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          // iOS/macOS: transición nativa por defecto.
        },
      ),
    );
  }

  /// Escala tipográfica para tablet: mismos roles de M3, tamaños mínimos
  /// legibles y pesos algo más marcados en títulos.
  static TextTheme _textTheme(TextTheme base, ColorScheme scheme) {
    TextStyle? t(TextStyle? s, double size, FontWeight w, {double? height}) =>
        s?.copyWith(fontSize: size, fontWeight: w, height: height, color: scheme.onSurface);
    return base.copyWith(
      displaySmall: t(base.displaySmall, 34, FontWeight.w600),
      headlineMedium: t(base.headlineMedium, 28, FontWeight.w600),
      headlineSmall: t(base.headlineSmall, 24, FontWeight.w600),
      titleLarge: t(base.titleLarge, 20, FontWeight.w600),
      titleMedium: t(base.titleMedium, 16, FontWeight.w600),
      titleSmall: t(base.titleSmall, 14, FontWeight.w600),
      bodyLarge: t(base.bodyLarge, 16, FontWeight.w400, height: 1.4),
      bodyMedium: t(base.bodyMedium, 14, FontWeight.w400, height: 1.4),
      bodySmall: base.bodySmall?.copyWith(
          fontSize: 12.5, color: scheme.onSurfaceVariant),
      labelLarge: t(base.labelLarge, 14, FontWeight.w600),
      labelMedium: t(base.labelMedium, 12.5, FontWeight.w600),
      labelSmall: base.labelSmall?.copyWith(
          fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
    );
  }
}
