// test/services/impl/local_image_data_service_test.dart
//
// Tests LocalImageDataService using a temp directory (no path_provider).
// Run: flutter test test/services/local_image_data_service_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:stuff/core/helpers/image_ref.dart';
import 'package:stuff/services/impl/local_image_data_service.dart';

void main() {
  late Directory tempRoot;
  late Directory imagesBaseDir;
  late LocalImageDataService svc;

  Future<File> writeTempImage(String nameWithExt, List<int> bytes) async {
    final f = File(p.join(tempRoot.path, nameWithExt));
    await f.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
    return f;
  }

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('imgs_test_');
    imagesBaseDir = Directory(p.join(tempRoot.path, 'app_support'));
    await imagesBaseDir.create(recursive: true);

    // Point the service at our temp base dir (no path_provider).
    svc = LocalImageDataService(baseDir: imagesBaseDir, subdirName: 'images');
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('init()', () {
    test('is idempotent', () async {
      expect(svc.isInitialized, isFalse);
      await svc.init();
      expect(svc.isInitialized, isTrue);

      // Second call does nothing harmful.
      await svc.init();
      expect(svc.isInitialized, isTrue);
    });

    test('concurrent init calls complete successfully (no race)', () async {
      final results = await Future.wait<void>([
        svc.init(),
        svc.init(),
        svc.init(),
      ]);
      expect(results.length, 3);
      expect(svc.isInitialized, isTrue);

      final dir = Directory(p.join(imagesBaseDir.path, 'images'));
      expect(await dir.exists(), isTrue);
    });
  });

  group('save/get/delete image', () {
    test(
      'saveImage writes file and returns GUID with original extension (allowed ext)',
      () async {
        await svc.init();
        final src = await writeTempImage('sample.png', [0, 1, 2, 3]);
        final guid = await svc.saveImage(src);

        // Expect GUID + .png
        expect(guid, endsWith('.png'));

        // File must exist in service dir.
        final savedPath = p.join(imagesBaseDir.path, 'images', guid);
        expect(await File(savedPath).exists(), isTrue);

        // getImage (verifyExists=true) should return a FileImageRef.
        final ref = await svc.getImage(guid, verifyExists: true);
        expect(ref, isA<FileImageRef>());
        final fileRef = ref as FileImageRef;
        expect(fileRef.path, savedPath);
      },
    );

    test('saveImage falls back to .jpg for unknown extensions', () async {
      await svc.init();
      final src = await writeTempImage('weird.ext', [1, 2, 3]);
      final guid = await svc.saveImage(src);
      expect(guid, endsWith('.jpg')); // fallback

      final savedPath = p.join(imagesBaseDir.path, 'images', guid);
      expect(await File(savedPath).exists(), isTrue);
    });

    test(
      'getImage returns null when verifyExists=true and file missing',
      () async {
        await svc.init();
        final ref = await svc.getImage('not_there.png', verifyExists: true);
        expect(ref, isNull);
      },
    );

    test(
      'getImage returns FileImageRef when verifyExists=false even if file missing',
      () async {
        await svc.init();
        final ref = await svc.getImage('maybe_later.png', verifyExists: false);
        expect(ref, isA<FileImageRef>());
        final path = (ref as FileImageRef).path;
        expect(path, p.join(imagesBaseDir.path, 'images', 'maybe_later.png'));
      },
    );

    test('deleteImage removes just the target file', () async {
      await svc.init();
      final a = await writeTempImage('a.png', [1]);
      final b = await writeTempImage('b.png', [2]);

      final ga = await svc.saveImage(a);
      final gb = await svc.saveImage(b);

      final pa = File(p.join(imagesBaseDir.path, 'images', ga));
      final pb = File(p.join(imagesBaseDir.path, 'images', gb));

      expect(await pa.exists(), isTrue);
      expect(await pb.exists(), isTrue);

      await svc.deleteImage(ga);

      expect(await pa.exists(), isFalse);
      expect(await pb.exists(), isTrue);
    });

    test(
      'deleteAllImages clears directory contents but leaves directory',
      () async {
        await svc.init();

        // Save a couple of files
        final f1 = await writeTempImage('x.png', [9, 9]);
        final f2 = await writeTempImage('y.jpg', [8, 8]);

        await svc.saveImage(f1);
        await svc.saveImage(f2);

        final dir = Directory(p.join(imagesBaseDir.path, 'images'));
        expect(await dir.exists(), isTrue);

        await svc.deleteAllImages();

        // Directory exists, but empty
        expect(await dir.exists(), isTrue);
        final entries = await dir.list().toList();
        expect(entries, isEmpty);
      },
    );

    test('getImage throws on invalid/traversal GUID', () async {
      await svc.init();
      expect(() => svc.getImage('../evil.png'), throwsA(isA<ArgumentError>()));
      expect(() => svc.getImage(r'..\evil.png'), throwsA(isA<ArgumentError>()));
      expect(
        () => svc.getImage('nested/evil.png'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('saveImage throws when source file does not exist', () async {
      await svc.init();
      final ghost = File(p.join(tempRoot.path, 'ghost.png'));
      await expectLater(svc.saveImage(ghost), throwsA(isA<ArgumentError>()));
    });
  });

  group('basic integration with ImageRef', () {
    test('provider path matches images dir (sanity)', () async {
      await svc.init();
      final src = await writeTempImage('ok.png', [0, 0, 0, 0]);
      final guid = await svc.saveImage(src);
      final ref = await svc.getImage(guid);

      expect(ref, isA<FileImageRef>());
      final path = (ref as FileImageRef).path;
      expect(p.dirname(path), p.join(imagesBaseDir.path, 'images'));
    });

    test('getImage returns null for deleted image', () async {
      await svc.init();
      final src = await writeTempImage('del.png', [1, 1, 1, 1]);
      final guid = await svc.saveImage(src);

      expect(await svc.getImage(guid), isNotNull);
      await svc.deleteImage(guid);
      expect(await svc.getImage(guid), isNull);
    });
  });
}
