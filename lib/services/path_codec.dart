// SPDX-License-Identifier: GPL-3.0-or-later

/// Traduce rutas de imagen entre memoria (absolutas) y disco (relativas a la
/// carpeta de datos).
///
/// En disco se guardan relativas para que una nota no dependa de dónde vive
/// la carpeta de datos: restaurar un respaldo en otro dispositivo o en otra
/// ruta no exige reescribir los JSON, y la limpieza de huérfanas compara
/// nombres en vez de rutas absolutas que pueden diferir en separadores.
///
/// En memoria siguen absolutas: pintar, exportar y respaldar en Drive no
/// cambian.
class PathCodec {
  PathCodec(String basePath)
    : _base = basePath,
      _normalizedBase = _normalize(basePath);

  /// Base tal como la entrega el sistema: se usa al reconstruir para que las
  /// rutas resultantes tengan la misma forma que las que arma el resto de la
  /// app (`'${base.path}/images/…'`).
  final String _base;
  final String _normalizedBase;

  /// Absoluta → relativa si está dentro de la base. Lo que queda fuera
  /// (archivos del usuario, marcadores `inklus://`) no se toca.
  String encode(String path) {
    final normalized = _normalize(path);
    final prefix = '$_normalizedBase/';
    return normalized.startsWith(prefix)
        ? normalized.substring(prefix.length)
        : path;
  }

  /// Relativa → absoluta. Las absolutas (datos viejos) y los esquemas pasan
  /// sin cambios, así un JSON antiguo sigue cargando.
  String decode(String stored) {
    if (_isAbsoluteOrUri(stored)) return stored;
    return '$_base/$stored';
  }

  /// Relativiza las rutas de imagen de un JSON de nota (in situ).
  void encodeNoteJson(Map<String, dynamic> note) => _rewrite(note, encode);

  /// Inverso de [encodeNoteJson] (in situ).
  void decodeNoteJson(Map<String, dynamic> note) => _rewrite(note, decode);

  // Solo dos campos de una nota guardan rutas: la imagen insertada y el fondo
  // de página (plantilla de imagen o página de PDF). Recorrerlos a mano evita
  // tocar los miles de puntos de trazo.
  static void _rewrite(Map<String, dynamic> note, String Function(String) f) {
    for (final page in note['pages'] as List? ?? const []) {
      if (page is! Map) continue;
      for (final image in page['images'] as List? ?? const []) {
        if (image is Map && image['path'] is String) {
          image['path'] = f(image['path'] as String);
        }
      }
      final template = page['template'];
      if (template is Map && template['imagePath'] is String) {
        template['imagePath'] = f(template['imagePath'] as String);
      }
    }
  }

  static String _normalize(String path) => path.replaceAll(r'\', '/');

  static final _drivePrefix = RegExp(r'^[A-Za-z]:[\\/]');

  static bool _isAbsoluteOrUri(String path) =>
      path.startsWith('/') ||
      path.startsWith(r'\') ||
      path.contains('://') ||
      _drivePrefix.hasMatch(path);
}
