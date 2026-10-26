# 🚀 Publicar una versión

Distribución en **Google Play** (AAB, empezando por el track de prueba cerrada) y en **GitHub Releases** (APK/AAB firmados por la CI en tags `v*`). Licencia GPL-3.0-or-later.

## Antes de etiquetar

1. `flutter analyze` (0 issues), `flutter test`, `flutter test integration_test -d <android>`.
2. Prueba en tablet con el guion de [`testing.md`](testing.md).
3. Sube la versión en **`pubspec.yaml`** (`version: X.Y.Z+N`), que es el único lugar donde vive. Ver [Numeración](#numeración).
4. Añade la sección `## [X.Y.Z] — AAAA-MM-DD` a `CHANGELOG.md`, **en español y en inglés** (sección `### English`): el workflow copia esa sección completa a las notas de la release.
5. Actualiza `ROADMAP.md` si cambia el estado del proyecto.

## Numeración

- `version: X.Y.Z+N` en `pubspec.yaml`. `X.Y.Z` es el `versionName` que se ve en Play y `N` es el `versionCode`.
- `N` **solo sube** y nunca se reutiliza: Play rechaza un AAB con un `versionCode` que ya subiste, aunque haya sido a otra pista.
- `0.x.y` durante la beta y `1.0.0` en la salida pública. La primera versión de KrakInk es `0.1.0+1`. Los tags `v1.8.0` y `v1.9.0` son del proyecto original.
- La app lee la versión del paquete instalado (`lib/services/app_version.dart`), y de ahí la toman Ajustes y el registro de errores. Si en Ajustes aparece `KrakInk ?`, la lectura falló y el registro tiene una entrada `app.version`.

## Etiquetar

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

La CI (`.github/workflows/ci.yml`, job `release`) comprueba que el tag coincida con `pubspec.yaml`, firma el APK/AAB y crea la release con las notas del CHANGELOG.

## Firma (una sola vez, manual)

- Genera un keystore **y guárdalo a buen recaudo**: si cambia la clave, los usuarios deben desinstalar para actualizar.
- Secretos del repositorio (Settings → Secrets → Actions): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
- Para builds locales firmados usa `android/key.properties` (**nunca versionado**) con las mismas cuatro claves; sin él, cualquier build de release falla a propósito (`checkReleaseSigning`).
- Para huellas SHA-1 (registro de Google Sign-In) usa `keytool -list`; son públicas, las contraseñas no.
- **Nunca** subas `key.properties`, `*.jks` ni `client_secret*.json`; la CI ejecuta gitleaks.

## Google Sign-In / Drive

Las SHA-1 de debug, de la clave de subida y de la clave de **Play App Signing** (Play Console → Integridad de la app) deben estar registradas en Google Cloud (cliente OAuth Android). Sin la de Play, el login de Drive falla en las instalaciones que vienen de la tienda. Para uso público, publica la pantalla de consentimiento (*Publish app*) con la URL de [`privacy.md`](privacy.md); si no, 100 usuarios de prueba y tokens de 7 días.

## Después

Descarga el APK de la release y compruébalo en un dispositivo limpio (instalación, abrir cuaderno, escribir, exportar).
