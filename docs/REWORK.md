# Inklus — Plan de rework (base, comunidad y UI premium)

> Estado: **planificado, sin ejecutar** (auditoría del 2026-10-14). Documento de traspaso: quien retome el trabajo puede empezar aquí. Contexto técnico en `ROADMAP.md`; arquitectura en `docs/ARCHITECTURE.md` (Fase A la crea a partir de la guía técnica actual).

## Objetivo
Dejar Inklus listo para colaboradores y hacer que biblioteca, portadas y barra del editor se sientan como un producto premium (nivel GoodNotes/Notability), manteniendo: gratis, offline-first, GPL-3.0-or-later, multilingüe.

## Reglas del proyecto (aplican a toda ejecución)
- Todo a nombre del mantenedor (Pedro, `Pedroj-64`) con su identidad de git/gh. Sin trailers ni menciones de herramientas de generación de código en commits, PR, docs o código.
- No hacer commit/push/PR sin petición explícita del mantenedor.
- Nunca versionar secretos (`key.properties`, `*.jks`, `client_secret*.json`).
- Idiomas objetivo: es, en, pt-BR, fr, de. Texto nuevo siempre por ARB (`context.l10n`).
- Historial de git: no reescribir (decisión tomada).

## Fase A — Limpieza y gobernanza (sin tocar código de la app)
1. **Limpiar el árbol**: `ROADMAP.md` (líneas 3 y 5, "para la IA" → "para colaboradores"); `.gitignore` (bloque de asistentes, L154-187: dejar reglas neutras; lo local va al ignore global del desarrollador); borrar `.github/modernize/`; `AGENTS.md` sale del repo y su contenido pasa a `docs/ARCHITECTURE.md` redactado como guía para contribuidores.
2. **Archivos de comunidad** (es/en donde sea público):
   - `CONTRIBUTING.md` (+ `.es.md`): setup, `flutter analyze` en 0, tests, Conventional Commits, ramas, DCO (`Signed-off-by`, sin CLA), flujo de PR, cómo traducir.
   - `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), `SECURITY.md` (reporte privado vía GitHub Security Advisories), `SUPPORT.md`, `GOVERNANCE.md` corto (mantenedor principal, cómo se decide), `CODEOWNERS`.
   - `.github/ISSUE_TEMPLATE/{bug,feature,translation}.yml` + `config.yml`, `.github/pull_request_template.md`, `dependabot.yml`.
   - Licencia: mantener GPL-3.0-or-later; documentar fuentes OFL (`third_party_licenses/`) y regla CC0/CC-BY para el marketplace.
3. **Docs**: `docs/ARCHITECTURE.md`, `docs/DESIGN_SYSTEM.md` (tokens, reglas de UI, checklist premium), `docs/TRANSLATING.md`, `docs/RELEASING.md` (firma, tags, CHANGELOG; sin secretos). Enlazar desde ambos README. Reducir `ROADMAP.md` a estado + próximas rondas.

## Fase B — Datos seguros
- `WidgetsBindingObserver` → `flush()` en `paused/inactive/detached` (`lib/logic/canvas_controller.dart`, `lib/ui/home_screen.dart`).
- Aviso visible si falla el guardado (hoy solo `debugPrint` en `saveNow`); enrutar los `catch (_)` críticos de `storage_service.dart` a `ErrorLog`.
- `schemaVersion` por nota (`Note.toJson/fromJson`) con migración trivial y test de ida y vuelta.
- `analysis_options.yaml`: `strict-casts`, `strict-raw-types`, `unawaited_futures`, `use_build_context_synchronously`, `prefer_const_constructors`; corregir lo que salga sin suprimir.

## Fase C — Consistencia de UI y sensación premium
Reutilizar `ui/theme/tokens.dart`, `inklus_colors.dart`, `ui/widgets/page_scaffold.dart`, `dialogs.dart`.
1. Borrar código muerto `lib/utils/design_tokens.dart` y `lib/utils/theme_colors.dart`.
2. Tokens nuevos: elevaciones/sombras (hoy 6 `BoxShadow` y 12 `elevation:` sueltos) y roles de texto para los ~58 `fontSize:` inline; unificar el azul de marca (`app_theme.dart:19` 0xFF3B6FF6 vs `constants.dart:135` 0xFF3B82F6; `kAccentDark`).
3. Migrar a tokens: `create_notebook_screen.dart` (45 literales), `template_picker_sheet.dart` (36), `notebook_library.dart` (17), `custom_color_dialog.dart`, `layers_sidebar.dart` (L160 rompe modo oscuro). Quitar texto <12 pt y objetivos <48 dp.
4. Componentes únicos: biblioteca usa `EmptyState`; hojas con `SheetHeader`; menú de tarjetas con `MenuAnchor` (`note_list_screen.dart:339`); helper único de snackbar; `showConfirmDialog/showTextPrompt` con etiquetas l10n obligatorias.
5. **Notas elegantes**: portadas con miniatura de la página 1 o placa de título (fuentes empaquetadas), color de título con contraste automático, radio del painter = radio de tarjeta, sombras en capas, `Hero` tarjeta→editor, feedback de pulsación y háptico; barra del editor flotante y redondeada con glifos propios (punta, grosor y color en vivo); `textScaler` y celdas flexibles; ancho máximo de contenido en pantallas anchas; semantics en swatches, portadas y miniaturas.
6. Verificación visual: `flutter test tool/screenshots/screenshots_test.dart` en claro/oscuro, es/en y un idioma largo (de).

## Fase D — Multilingüe
- Añadir `app_pt.arb` (pt-BR), `app_fr.arb`, `app_de.arb` desde `app_es.arb` (603 claves). Extender `test/l10n_test.dart` a los cinco idiomas.
- Pasar a l10n los literales restantes (`Half Ltr`, `Hex`, nombres de `kCoverColors`). Los títulos por defecto guardados en datos ('Sin título', 'Mi cuaderno') quedan como deuda documentada: clave neutra + migración en una ronda posterior.
- READMEs pt/fr/de mínimos o dejar es/en y pedir ayuda comunitaria en `docs/TRANSLATING.md`.

## Ronda 2 (después)
Latencia de tinta (`getCoalescedEvents`, puntos predichos, trazo activo incremental, curva de presión/calibración); dividir `StorageService` (1606 l.) y `HomeScreen` (1783 l.); tests de borrador, lazo, undo, painters con goldens; PDF vectorial; accesibilidad completa; marketplace con contenido real.

## Verificación
- `flutter analyze` → 0 issues; `flutter test`; `flutter test integration_test -d linux`.
- Capturas claro/oscuro y recorrido manual biblioteca → cuaderno → editor (`flutter run -d linux`); prueba en tablet según `docs/testing.md`.
- Búsqueda en el árbol (excluyendo `.git`, `build`, `.dart_tool`) de menciones a herramientas de generación de código o a "la IA" sin resultados, salvo el reconocimiento de escritura on-device (ML Kit), que es legítimo.

---

# Anexo — Hallazgos de la auditoría (2026-10-14)

## Gobernanza
- Existen: `LICENSE` (GPL-3.0), `CHANGELOG.md`, `ROADMAP.md`, `docs/{privacy,testing}.md`, `third_party_licenses/` (8 OFL), `marketplace/`, CI en `.github/workflows/ci.yml`.
- Faltan: CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, SUPPORT, GOVERNANCE, CODEOWNERS, plantillas de issue/PR, dependabot.
- Siete commits antiguos (v1.1–1.3) llevan trailers automáticos de una herramienta externa; se dejan como están (no reescribir historia).
- i18n: solo es/en, 603 claves cada uno, paridad exigida por `test/l10n_test.dart`.

## Código y lienzo
1. Sin flush de autoguardado al pausar la app → se pueden perder los últimos trazos (<600 ms).
2. `saveNow` solo hace `debugPrint` si falla; 19 `catch (_)` silenciosos.
3. Sin `schemaVersion` por nota.
4. Tinta: sin `getCoalescedEvents` ni puntos predichos; presión 0/>1 → 0.5, sin curva ni tilt; `getStroke` recalcula el trazo activo entero por frame (`world_painter.dart:466-476`); `CanvasPainter.shouldRepaint` crea listas por llamada (`drawing_canvas.dart:230-241`).
5. Archivos grandes: `home_screen.dart` 1783, `storage_service.dart` 1606, `canvas_controller.dart` 1544, `drawing_canvas.dart` 1273, `notebook_library.dart` 1195.
6. Sin tests de: borrador, lazo, undo_stack, bucket_fill, stroke_engine, painters (sin goldens), Drive, OCR, PDF.
7. Solo `flutter_lints`; importación/exportación PDF raster; `cupertino_icons` y `_discoveryapis_commons` posiblemente innecesarios; único TODO en `world_painter.dart:61`.

## UI
- Sistema de diseño existente: `ui/theme/{app_theme,inklus_colors,tokens}.dart`, `ui/widgets/{page_scaffold,dialogs}.dart`. Adopción: Spacing 211 usos, Radii 37, Motion 7; ~58 `fontSize:` inline, ~69 `Color(0x..)`, 51 `Colors.x`.
- Violaciones de las reglas de UI: `layers_sidebar.dart:160`, `text_edit_overlay.dart:295,712`, `notebook_library.dart:968`, `create_notebook_screen.dart:449,463`, `template_picker_sheet.dart:806`, `tool_popovers.dart:298,351`. Texto <12 pt: `note_list_screen.dart:509`, `layers_sidebar.dart:195,286`, `custom_color_dialog.dart:61,82`, `template_picker_sheet.dart:374,907`. Objetivos <48 dp: `editor_toolbar.dart:382`, `notebook_library.dart:986`.
- Inconsistencias: empty state duplicado (`notebook_library.dart:750-821`); hojas sin `SheetHeader` (`notebook_library.dart:293,455`, `home_screen.dart:659,1408`, `template_picker_sheet.dart`); `MenuAnchor` vs `PopupMenuButton`; 'Aceptar/Cancelar' fijos en `dialogs.dart:19-20,113-114`; ~33 snackbars sin helper.
- Brechas frente a GoodNotes/Notability/Samsung Notes: portadas sin miniatura ni materiales, sin `Hero`, barra no flotante, iconos genéricos, sin multiselección ni arrastrar a carpetas, sin `textScaler`, sin ancho máximo, semantics incompletos.

## Referentes (solo ideas; respetar licencias)
Saber (Flutter, GPL-3.0, github.com/saber-notes/saber), Xournal++ (formato `.xopp`, audio, LaTeX), GoodNotes y Notability (UX). Flutter y DevTools como modelo de CONTRIBUTING y CODE_OF_CONDUCT.
