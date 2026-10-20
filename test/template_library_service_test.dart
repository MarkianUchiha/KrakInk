// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/app_paths.dart';
import 'package:inklus/services/template_library_service.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('inklus_tpl_');
    AppPaths.rootOverride = root;
  });

  tearDown(() {
    AppPaths.rootOverride = null;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test(
    'el índice guarda la ruta relativa y al cargar vuelve absoluta',
    () async {
      final source = File('${root.path}/origen.png')..writeAsBytesSync([7, 8]);

      final library = TemplateLibraryService();
      await library.init();
      final entry = await library.save(
        name: 'Cuadrícula',
        sourceImagePath: source.path,
        infiniteFill: false,
      );

      final index =
          jsonDecode(
                File('${root.path}/templates/index.json').readAsStringSync(),
              )
              as List;
      expect((index.single as Map)['imagePath'], '${entry.id}.png');

      final reloaded = TemplateLibraryService();
      await reloaded.init();
      final path = reloaded.entries.single.imagePath;
      expect(File(path).readAsBytesSync(), [7, 8]);
    },
  );

  test(
    'el índice sigue funcionando si la carpeta de datos cambia de sitio',
    () async {
      final source = File('${root.path}/origen.png')..writeAsBytesSync([1]);
      final library = TemplateLibraryService();
      await library.init();
      await library.save(
        name: 'Pautado',
        sourceImagePath: source.path,
        infiniteFill: true,
      );

      // Simula restaurar el respaldo en otro dispositivo: misma estructura,
      // otra carpeta raíz.
      final moved = Directory.systemTemp.createTempSync('inklus_tpl_moved_');
      try {
        final from = Directory('${root.path}/templates');
        final to = Directory('${moved.path}/templates')..createSync();
        for (final f in from.listSync().whereType<File>()) {
          f.copySync('${to.path}/${f.uri.pathSegments.last}');
        }
        from.deleteSync(recursive: true);
        AppPaths.rootOverride = moved;

        final restored = TemplateLibraryService();
        await restored.init();
        expect(File(restored.entries.single.imagePath).existsSync(), isTrue);
      } finally {
        moved.deleteSync(recursive: true);
      }
    },
  );
}
