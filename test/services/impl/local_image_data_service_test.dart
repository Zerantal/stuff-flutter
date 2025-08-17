// test/services/impl/local_image_data_service_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/services/impl/local_image_data_service.dart';

Future<File> _writeTempImage(Directory dir, String name, List<int> bytes) async {
  final f = File(p.join(dir.path, name));
  await f.create(recursive: true);
  await f.writeAsBytes(bytes);
  return f;
}

void main() {
  late Directory tempRoot;
  late Directory appDataRoot;
  late LocalImageDataService svc;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('local_img_svc_test_');
    appDataRoot = Directory(p.join(tempRoot.path, 'appdata'));
    svc = LocalImageDataService(rootOverride: appDataRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('LocalImageDataService', () {
    test('init creates image storage dir', () async {
      expect(appDataRoot.existsSync(), isFalse);
      await svc.init();
      // Service stores under "<root>/images"
      final imagesDir = Directory(p.join(appDataRoot.path, 'images'));
      expect(imagesDir.existsSync(), isTrue);
    });

    test('saveImage copies by default; deleteSource moves', () async {
      await svc.init();

      final src1 = await _writeTempImage(tempRoot, 'one.png', [1, 2, 3]);
      final guid1 = await svc.saveImage(src1);
      final path1 = p.join(appDataRoot.path, 'images', guid1);
      expect(File(path1).existsSync(), isTrue, reason: 'copied to images dir');
      expect(src1.existsSync(), isTrue, reason: 'source remains when deleteSource=false');

      final src2 = await _writeTempImage(tempRoot, 'two.jpg', [9, 9]);
      final guid2 = await svc.saveImage(src2, deleteSource: true);
      final path2 = p.join(appDataRoot.path, 'images', guid2);
      expect(File(path2).existsSync(), isTrue, reason: 'moved to images dir');
      expect(src2.existsSync(), isFalse, reason: 'source removed when deleteSource=true');
    });

    test('getImage returns FileImageRef with expected path', () async {
      await svc.init();

      final src = await _writeTempImage(tempRoot, 'cat.png', [1, 1, 2, 3]);
      final guid = await svc.saveImage(src);
      final ref = await svc.getImage(guid);

      expect(ref, isA<FileImageRef>());
      final path = (ref as FileImageRef).path;
      expect(path, p.join(appDataRoot.path, 'images', guid));
    });

    test('refForGuid returns FileImageRef without IO', () async {
      await svc.init();
      // produce any guid (no actual file)
      const guid = 'abc.png';
      final ref = svc.refForGuid(guid);
      expect(ref, isA<FileImageRef>());
      final path = (ref as FileImageRef).path;
      // Under the hood rootDir points to "<root>/images"
      expect(p.dirname(path), p.join(appDataRoot.path, 'images'));
    });

    test('deleteImage removes just the target file', () async {
      await svc.init();
      final a = await _writeTempImage(tempRoot, 'a.png', [1]);
      final b = await _writeTempImage(tempRoot, 'b.png', [2]);

      final ga = await svc.saveImage(a);
      final gb = await svc.saveImage(b);

      final pa = File(p.join(appDataRoot.path, 'images', ga));
      final pb = File(p.join(appDataRoot.path, 'images', gb));
      expect(pa.existsSync(), isTrue);
      expect(pb.existsSync(), isTrue);

      await svc.deleteImage(ga);

      expect(pa.existsSync(), isFalse);
      expect(pb.existsSync(), isTrue);
    });

    test('getImage returns null for deleted image', () async {
      await svc.init();
      final src = await _writeTempImage(tempRoot, 'del.png', [1, 1, 1, 1]);
      final guid = await svc.saveImage(src);

      expect(await svc.getImage(guid), isNotNull);
      await svc.deleteImage(guid);
      expect(await svc.getImage(guid), isNull);
    });
  });
}
