// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:flutter_test/flutter_test.dart';
import 'package:inklus/services/path_codec.dart';

void main() {
  group('PathCodec POSIX', () {
    final codec = PathCodec('/data/user/0/app/files/inklus');

    test('encode quita la base y deja la ruta relativa', () {
      expect(
        codec.encode('/data/user/0/app/files/inklus/images/a.png'),
        'images/a.png',
      );
    });

    test('encode deja intacta una ruta fuera de la base', () {
      expect(codec.encode('/sdcard/Download/a.png'), '/sdcard/Download/a.png');
    });

    test('encode no confunde un prefijo parcial con la base', () {
      expect(
        codec.encode('/data/user/0/app/files/inklus2/images/a.png'),
        '/data/user/0/app/files/inklus2/images/a.png',
      );
    });

    test('encode deja intactos los marcadores con esquema', () {
      expect(codec.encode('krakink://images/a.png'), 'krakink://images/a.png');
    });

    test('decode une una ruta relativa a la base', () {
      expect(
        codec.decode('images/a.png'),
        '/data/user/0/app/files/inklus/images/a.png',
      );
    });

    test('decode deja intactas las rutas absolutas y los esquemas', () {
      expect(
        codec.decode('/otra/base/images/a.png'),
        '/otra/base/images/a.png',
      );
      expect(codec.decode('krakink://images/a.png'), 'krakink://images/a.png');
    });

    test('encode y decode son inversos dentro de la base', () {
      const abs = '/data/user/0/app/files/inklus/restored/nb1/b.jpg';
      expect(codec.decode(codec.encode(abs)), abs);
    });
  });

  group('PathCodec Windows', () {
    final codec = PathCodec(r'C:\Users\dev\AppData\Roaming\app\inklus');

    test('encode acepta separadores mezclados', () {
      expect(
        codec.encode(r'C:\Users\dev\AppData\Roaming\app\inklus/images\a.png'),
        'images/a.png',
      );
      expect(
        codec.encode('C:/Users/dev/AppData/Roaming/app/inklus/images/a.png'),
        'images/a.png',
      );
    });

    test('decode reconoce rutas con letra de unidad como absolutas', () {
      expect(codec.decode(r'D:\fotos\a.png'), r'D:\fotos\a.png');
    });

    test('decode usa la base tal como se dio', () {
      expect(
        codec.decode('images/a.png'),
        r'C:\Users\dev\AppData\Roaming\app\inklus/images/a.png',
      );
    });
  });

  group('PathCodec sobre JSON de nota', () {
    final codec = PathCodec('/base');

    Map<String, dynamic> noteJson(String imgPath, String? tplPath) => {
      'id': 'n1',
      'pages': [
        {
          'images': [
            {'id': 'i1', 'path': imgPath},
          ],
          'template': {'kind': 'image', 'imagePath': tplPath},
        },
      ],
    };

    test('encodeNoteJson relativiza imágenes y fondo de página', () {
      final json = noteJson('/base/images/a.png', '/base/pdf_imports/p1.png');
      codec.encodeNoteJson(json);
      final page = (json['pages'] as List).single as Map;
      expect(((page['images'] as List).single as Map)['path'], 'images/a.png');
      expect((page['template'] as Map)['imagePath'], 'pdf_imports/p1.png');
    });

    test('decodeNoteJson vuelve a rutas absolutas', () {
      final json = noteJson('images/a.png', 'pdf_imports/p1.png');
      codec.decodeNoteJson(json);
      final page = (json['pages'] as List).single as Map;
      expect(
        ((page['images'] as List).single as Map)['path'],
        '/base/images/a.png',
      );
      expect(
        (page['template'] as Map)['imagePath'],
        '/base/pdf_imports/p1.png',
      );
    });

    test('tolera notas sin páginas, sin imágenes o sin fondo', () {
      final empty = <String, dynamic>{'id': 'n1'};
      codec.encodeNoteJson(empty);
      expect(empty, {'id': 'n1'});

      final noTpl = noteJson('/base/images/a.png', null);
      codec.encodeNoteJson(noTpl);
      final page = (noTpl['pages'] as List).single as Map;
      expect((page['template'] as Map)['imagePath'], isNull);
    });
  });
}
