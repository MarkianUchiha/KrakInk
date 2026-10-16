# 🌍 Traducir Inklus

La app sigue el idioma del sistema. Idiomas: **es** (fuente), **en**, **pt** (portugués de Brasil, `app_pt.arb`), **fr** y **de**; cualquier otro cae en inglés (`resolveAppLocale` en `lib/app.dart`). Las traducciones pt/fr/de son un primer borrador: las correcciones de hablantes nativos son muy bienvenidas. No hace falta saber Dart: solo editar un archivo `.arb` (JSON).

## Corregir una traducción

1. Abre `lib/l10n/app_<idioma>.arb`.
2. Edita el valor (no la clave). Conserva los marcadores `{nombre}` y los plurales `{n, plural, one{…} other{…}}`.
3. Abre un PR (o un issue de traducción con la clave y el texto propuesto).

## Añadir un idioma

1. Copia `lib/l10n/app_es.arb` a `lib/l10n/app_<código>.arb` (por ejemplo `app_pt.arb`, `app_fr.arb`, `app_de.arb`; para variantes regionales `app_pt_BR.arb`).
2. Cambia `"@@locale"` y traduce todos los valores. Las entradas `@clave` (metadatos) solo viven en `app_es.arb`.
3. `flutter gen-l10n` (también lo hace `flutter pub get`) y `flutter test test/l10n_test.dart`: exige que todos los idiomas tengan **exactamente las mismas claves** y los mismos marcadores.
4. Prueba la app con el idioma del sistema o con `kAppLocale` (solo para capturas/tests) y revisa desbordes en pantallas estrechas.

## Texto nuevo en el código

Nunca literales en widgets: añade la clave primero a `app_es.arb` (fuente) y a todos los demás ARB, y úsala con `context.l10n.clave`. Tras un `await` en un `State`, usa `_l10n`. Errores visibles: lanza `AppError(código)` y muéstralos con `userError(l10n, e)`.

## Qué no se traduce

Contenido guardado en datos (títulos por defecto, nombres de páginas/capas) se traduce al mostrarse con `displayTitle`; el catálogo remoto del marketplace y los diagnósticos técnicos/logs quedan como están.

## Estilo

Tono cercano y directo, igual que el español fuente. Mantén los términos de la interfaz coherentes (cuaderno/nota/página, lazo, borrador, regla). Si dudas, deja la frase en inglés y avísalo en el PR: otra persona puede revisarla.
