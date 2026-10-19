# 🚀 Publicar una versión

Distribución sin Google Play: **GitHub Releases** (APK/AAB firmados por la CI en tags `v*`) e idealmente IzzyOnDroid. Licencia GPL-3.0-or-later.

## Antes de etiquetar

1. `flutter analyze` (0 issues), `flutter test`, `flutter test integration_test -d <android>`.
2. Prueba en tablet con el guion de [`testing.md`](testing.md).
3. Sube la versión en **`pubspec.yaml`** (`version: X.Y.Z+N`, `N` siempre creciente) y en **`lib/constants.dart`** (`kAppVersion`). `test/app_version_test.dart` comprueba que coincidan.
4. Añade la sección `## [X.Y.Z] — AAAA-MM-DD` a `CHANGELOG.md`, **en español y en inglés** (sección `### English`): el workflow copia esa sección completa a las notas de la release.
5. Actualiza `ROADMAP.md` si cambia el estado del proyecto.

## Etiquetar

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

La CI (`.github/workflows/ci.yml`, job `release`) comprueba que el tag coincida con `pubspec.yaml`, firma el APK/AAB y crea la release con las notas del CHANGELOG.

## Firma (una sola vez, manual)

- Genera un keystore **y guárdalo a buen recaudo**: si cambia la clave, los usuarios deben desinstalar para actualizar.
- Secretos del repositorio (Settings → Secrets → Actions): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Para builds locales firmados usa `android/key.properties` (**nunca versionado**) con las mismas cuatro claves; sin él, release firma con la clave de debug.
- Para huellas SHA-1 (registro de Google Sign-In) usa `keytool -list`; son públicas, las contraseñas no.
- **Nunca** subas `key.properties`, `*.jks` ni `client_secret*.json`; la CI ejecuta gitleaks.

## Google Sign-In / Drive

Las SHA-1 de debug y de release deben estar registradas en Google Cloud (cliente OAuth Android). Para uso público, publica la pantalla de consentimiento (*Publish app*) con la URL de [`privacy.md`](privacy.md); si no, 100 usuarios de prueba y tokens de 7 días.

## Después

Descarga el APK de la release y compruébalo en un dispositivo limpio (instalación, abrir cuaderno, escribir, exportar).
