// test/path_provider_temporary_file_service_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:stuff/services/impl/path_provider_temporary_file_service.dart';

/// Fake path_provider that redirects Application Support to our sandbox.
class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.appSupport);
  final String appSupport;

  @override
  Future<String?> getApplicationSupportPath() async => appSupport;

  // Others not needed for this test.
}

Future<File> _makeTempFile(Directory root, String relPath, {int bytes = 32}) async {
  final f = File(p.join(root.path, relPath));
  await f.create(recursive: true);
  await f.writeAsBytes(List<int>.generate(bytes, (i) => i % 251));
  return f;
}

void main() {
  late Directory sandbox;
  late PathProviderTemporaryFileService service;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('tfs_sandbox_');
    PathProviderPlatform.instance = _FakePathProviderPlatform(sandbox.path);
    service = PathProviderTemporaryFileService(); // default staging dir name: 'staging'
  });

  tearDown(() async {
    try {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('startSession creates unique directories under Application Support/staging', () async {
    final s1 = await service.startSession(label: 'edit_location');
    final s2 = await service.startSession(label: 'edit_location');

    expect(await s1.dir.exists(), isTrue);
    expect(await s2.dir.exists(), isTrue);
    expect(s1.dir.path, isNot(equals(s2.dir.path)));

    // Under sandbox/staging
    final stagingRoot = p.join(sandbox.path, 'staging');
    expect(p.isWithin(stagingRoot, s1.dir.path), isTrue);
    expect(p.isWithin(stagingRoot, s2.dir.path), isTrue);
  });

  test('importFile copies when deleteSource=false and preserves preferredName', () async {
    final session = await service.startSession(label: 'copy');
    final src = await _makeTempFile(sandbox, 'pick/photo.jpg');

    final staged = await session.importFile(src, preferredName: 'desired.jpg', deleteSource: false);

    expect(await staged.exists(), isTrue);
    expect(p.basename(staged.path), equals('desired.jpg'));
    // Original remains
    expect(await src.exists(), isTrue);
  });

  test('importFile moves (rename or copy+delete) when deleteSource=true', () async {
    final session = await service.startSession(label: 'move');
    final src = await _makeTempFile(sandbox, 'pick/to_move.png');

    final staged = await session.importFile(src, preferredName: 'to_move.png', deleteSource: true);

    expect(await staged.exists(), isTrue);
    expect(await src.exists(), isFalse, reason: 'source should be deleted after move');
    expect(p.isWithin(session.dir.path, staged.path), isTrue);
  });

  test('importFile ensures unique destination names', () async {
    final session = await service.startSession(label: 'unique');
    final src1 = await _makeTempFile(sandbox, 'pick/dup.jpg');
    final src2 = await _makeTempFile(sandbox, 'pick/dup.jpg');

    final a = await session.importFile(src1, preferredName: 'dup.jpg');
    final b = await session.importFile(src2, preferredName: 'dup.jpg');

    expect(await a.exists(), isTrue);
    expect(await b.exists(), isTrue);
    expect(p.basename(a.path), equals('dup.jpg'));
    expect(p.basename(b.path), isNot(equals('dup.jpg')));
    // Usually "dup-1.jpg" (don’t hardcode exact suffix)
    expect(p.basenameWithoutExtension(b.path), startsWith('dup-'));
  });

  test('dispose(deleteContents: true) removes the session directory', () async {
    final session = await service.startSession(label: 'dispose_yes');
    // put a file inside
    await _makeTempFile(session.dir, 'x.bin');

    expect(await session.dir.exists(), isTrue);
    await session.dispose(deleteContents: true);
    expect(await session.dir.exists(), isFalse);
  });

  test('dispose(deleteContents: false) keeps the session directory', () async {
    final session = await service.startSession(label: 'dispose_no');
    await _makeTempFile(session.dir, 'y.bin');

    await session.dispose(deleteContents: false);
    expect(await session.dir.exists(), isTrue);
    // Clean up to keep sandbox tidy
    await session.dir.delete(recursive: true);
  });

  test('sweepExpired(Duration.zero) deletes all sessions under staging root', () async {
    // Create a couple of sessions and leave them on disk
    final s1 = await service.startSession(label: 'old1');
    final s2 = await service.startSession(label: 'old2');
    await _makeTempFile(s1.dir, 'a.txt');
    await _makeTempFile(s2.dir, 'b.txt');

    final stagingRoot = Directory(p.join(sandbox.path, 'staging'));
    expect(await stagingRoot.exists(), isTrue);
    final before = await stagingRoot.list().where((e) => e is Directory).toList();
    expect(before.length, greaterThanOrEqualTo(2));

    final removed = await service.sweepExpired(maxAge: Duration.zero);
    // At least the two we created should be removed
    expect(removed, greaterThanOrEqualTo(2));

    final existsAfter = await stagingRoot.exists();
    if (existsAfter) {
      final after = await stagingRoot.list().where((e) => e is Directory).toList();
      expect(after, isEmpty);
    }
  });
}
