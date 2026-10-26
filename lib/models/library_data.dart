// SPDX-License-Identifier: GPL-3.0-or-later

/// Carpeta de la biblioteca. Un cuaderno está en una sola carpeta o en
/// ninguna (`Notebook.folderId`).
class Folder {
  final String id;
  final String name;
  final DateTime createdAt;

  const Folder({required this.id, required this.name, required this.createdAt});

  Folder copyWith({String? name}) =>
      Folder(id: id, name: name ?? this.name, createdAt: createdAt);

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Contenido de `library.json`: lo que organiza la biblioteca y no
/// pertenece a un cuaderno concreto.
class LibraryData {
  final List<Folder> folders;

  /// Catálogo de etiquetas: las que se ofrecen aunque ningún cuaderno las use.
  final List<String> tags;

  /// Las etiquetas base ya se sembraron. Se guarda para no volver a crearlas
  /// si el usuario las borra.
  bool tagsSeeded;

  LibraryData({
    List<Folder>? folders,
    List<String>? tags,
    this.tagsSeeded = false,
  }) : folders = folders ?? [],
       tags = tags ?? [];

  factory LibraryData.fromJson(Map<String, dynamic> json) => LibraryData(
    folders: [
      for (final f in json['folders'] as List? ?? const [])
        Folder.fromJson(f as Map<String, dynamic>),
    ],
    tags: [for (final t in json['tags'] as List? ?? const []) t as String],
    tagsSeeded: json['tagsSeeded'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'folders': [for (final f in folders) f.toJson()],
    'tags': tags,
    'tagsSeeded': tagsSeeded,
  };

  /// Carpeta con ese nombre, sin distinguir mayúsculas ni espacios de los
  /// extremos. Los nombres son únicos: así un `.krakink` encuentra su
  /// carpeta por nombre al importarse.
  Folder? folderNamed(String name) {
    final key = name.trim().toLowerCase();
    for (final f in folders) {
      if (f.name.trim().toLowerCase() == key) return f;
    }
    return null;
  }
}
