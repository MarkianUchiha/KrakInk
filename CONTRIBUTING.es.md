# Contribuir a Inklus

*[Read in English](CONTRIBUTING.md)*

¡Gracias por ayudar! Inklus es una app de escritura a mano para tablets con stylus: gratuita, de código abierto (GPL-3.0-or-later) y *offline-first*. Todo sigue siendo gratis: sin funciones premium ni dependencias de pago.

## Primeros pasos

```bash
flutter pub get
flutter analyze                        # debe quedar en 0 issues
flutter test                           # tests unitarios y de widgets
flutter test integration_test -d <android> # flujos de punta a punta (dispositivo o emulador)
flutter run -d <android>                   # desarrollo en dispositivo o emulador
```

Flutter 3.47 / Dart 3.13. Antes de tocar el lienzo lee [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md): la sección «Flujos críticos» lista lo que no debe romperse (entrada con stylus y rechazo de palma, capas de pintado, deshacer/rehacer, exportación).

## Reglas básicas

- **Offline-first.** Nada local puede depender de la red ni de una cuenta. Google Drive es un respaldo opcional.
- **La interfaz sigue el sistema de diseño**: colores, medidas y roles de texto salen del tema, nunca literales. Ver [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md).
- **Todo texto visible va en los ARB** (`context.l10n.clave`). Ver [`docs/TRANSLATING.md`](docs/TRANSLATING.md).
- **Comentarios del código en español** (`app_es.arb` es la fuente); la interfaz está disponible en varios idiomas.
- **Nunca subas secretos** (`android/key.properties`, `*.jks`, `client_secret*.json`). La CI ejecuta un escaneo de secretos.
- Añade o actualiza tests cuando cambies lógica. Un arreglo de bug lleva su test de regresión.

## Flujo de trabajo

1. Abre un issue antes de cualquier cosa mayor que un arreglo pequeño, para acordar el enfoque.
2. Haz un fork y crea una rama desde `main`: `feat/nombre`, `fix/nombre`, `docs/nombre`.
3. PRs pequeños: una sola preocupación por PR.
4. `flutter analyze` limpio y `flutter test` en verde.
5. Abre el PR con la plantilla. Los cambios visuales llevan capturas (`flutter test tool/screenshots/screenshots_test.dart` renderiza la UI real sin dispositivo).

## Mensajes de commit

[Conventional Commits](https://www.conventionalcommits.org/es/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, con ámbito opcional (`fix(canvas): ...`). Vale español o inglés.

## Firma (DCO)

No hay CLA. En su lugar, certifica el [Certificado de Origen del Desarrollador](https://developercertificate.org/) firmando cada commit:

```bash
git commit -s -m "fix(canvas): ..."
```

Esto añade `Signed-off-by: Tu Nombre <tu@correo>` y significa que escribiste el cambio o tienes derecho a enviarlo bajo la licencia del proyecto.

## Traducir

Se agradecen idiomas nuevos y correcciones, y no hace falta saber Dart. Ver [`docs/TRANSLATING.md`](docs/TRANSLATING.md).

## Reportar problemas

- Bugs e ideas: usa las plantillas de issue.
- Seguridad: **no** abras un issue público; ver [`SECURITY.md`](SECURITY.md).
- Conducta: ver [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
