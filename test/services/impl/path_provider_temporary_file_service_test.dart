// test/services/impl/path_provider_temporary_file_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:stuff/services/impl/path_provider_temporary_file_service.dart';
import 'package:stuff/services/temporary_file_service_interface.dart';

void main() {
  late Directory base;
  late ITemporaryFileService svc;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('tfs_test_base_');
    svc = PathProviderTemporaryFileService(
      sessionPrefix: 'unit',
      baseDirOverride: base,
    );
  });

  tearDown(() async {
    // Best-effort cleanup of base temp dir
    try {
      if (await base.exists()) {
        await base.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('init creates a unique sessionDirectory under base', () async {
    await svc.init();
    final dir = svc.sessionDirectory;
    expect(await dir.exists(), isTrue);
    expect(p.isWithin(base.path, dir.path), isTrue);
  });

  test('copyToTemp copies file into session and preserves contents', () async {
    await svc.init();
    final srcDir = await Directory.systemTemp.createTemp('tfs_src_');
    final srcFile = File(p.join(srcDir.path, 'a.txt'));
    await srcFile.writeAsString('hello');

    final staged = await svc.copyToTemp(srcFile);
    expect(await staged.exists(), isTrue);
    expect(await staged.readAsString(), 'hello');
    expect(p.isWithin(svc.sessionDirectory.path, staged.path), isTrue);

    // Cleanup source dir
    await srcDir.delete(recursive: true);
  });

  test('copyToTemp on file already inside session returns same file', () async {
    await svc.init();
    final inside = File(p.join(svc.sessionDirectory.path, 'b.txt'));
    await inside.writeAsString('data');
    final r = await svc.copyToTemp(inside);
    expect(r.path, inside.path);
  });

  test('deleteFile removes file and does not throw if missing', () async {
    await svc.init();
    final f = File(p.join(svc.sessionDirectory.path, 'c.txt'));
    await f.writeAsString('bye');
    expect(await f.exists(), isTrue);

    await svc.deleteFile(f);
    expect(await f.exists(), isFalse);

    // Call again; should not throw
    await svc.deleteFile(f);
  });

  test('clearSession removes directory and resets state', () async {
    await svc.init();
    final dir = svc.sessionDirectory;
    expect(await dir.exists(), isTrue);

    await svc.clearSession();
    expect(await dir.exists(), isFalse);
    expect(() => svc.sessionDirectory, throwsA(isA<StateError>()));
  });

  test('dispose removes directory synchronously', () async {
    await svc.init();
    final dir = svc.sessionDirectory;
    svc.dispose(); // sync

    expect(dir.existsSync(), isFalse);
    // dispose is idempotent
    svc.dispose();
  });
}
