// SPDX-License-Identifier: GPL-3.0-or-later

/// Identidad de la app en un solo sitio.
///
/// Estos valores estaban repetidos a mano por varios servicios. Juntos aquí,
/// un cambio de marca toca este archivo y los recursos nativos de Android
/// (`build.gradle.kts`, `AndroidManifest.xml`, `MainActivity.kt`), que no
/// pueden leer Dart.
abstract final class Brand {
  /// Nombre visible.
  static const appName = 'KrakInk';

  /// Extensión de los cuadernos exportados, sin punto.
  static const fileExtension = 'krakink';

  /// Tipo MIME de los cuadernos exportados (Drive y "abrir con").
  static const mimeType = 'application/x-krakink';

  /// Prefijo de las imágenes embebidas dentro de un archivo exportado.
  static const imageScheme = 'krakink://';

  /// Carpeta raíz de los respaldos en Google Drive.
  static const driveFolder = 'KrakInk';

  /// Carpeta de datos dentro del almacenamiento privado de la app.
  static const dataDir = 'krakink';

  /// Canal con `MainActivity` para abrir archivos recibidos.
  static const openChannel = 'krakink/open';

  /// Prefijo de los archivos que la app genera (exportar página, respaldo…).
  static const filePrefix = 'krakink';

  static const repoUrl = 'https://github.com/MarkianUchiha/KrakInk';
}
