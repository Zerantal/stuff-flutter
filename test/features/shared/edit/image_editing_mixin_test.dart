import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/features/shared/edit/image_picking_mixin.dart';
import 'package:stuff/features/shared/state/image_set.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/services/contracts/temporary_file_service_interface.dart';

// ignore_for_file: INVALID_USE_OF_PROTECTED_MEMBER

/// ---------------------------------------------------------------------------
/// Minimal fakes for services
/// ---------------------------------------------------------------------------

class _FakeTempSession implements TempSession {
  _FakeTempSession(this.label);
  final String? label;
  bool disposed = false;

  @override
  Directory get dir => Directory.systemTemp;

  @override
  Future<File> importFile(File src, {String? preferredName, bool deleteSource = true}) async {
    // No-op for tests; return the same file.
    return src;
  }

  @override
  Future<void> dispose({bool deleteContents = true}) async {
    disposed = true;
  }
}

class _FakeTemporaryFileService implements ITemporaryFileService {
  _FakeTempSession? lastSession;

  @override
  Future<TempSession> startSession({String? label}) async {
    final s = _FakeTempSession(label);
    lastSession = s;
    return s;
  }

  @override
  Future<int> sweepExpired({Duration maxAge = const Duration(days: 30)}) async => 0;
}

class _FakeImageDataService implements IImageDataService {
  final List<File> savedFiles = [];
  final List<bool> deleteFlags = [];
  int _seq = 0;

  /// Return a synthetic ImageRef for a GUID
  @override
  ImageRef refForGuid(String guid) => ImageRef.asset('assets/$guid.png');

  /// Save a file and return a synthetic GUID
  @override
  Future<String> saveImage(File file, {bool deleteSource = false}) async {
    savedFiles.add(file);
    deleteFlags.add(deleteSource);
    _seq++;
    return 'guid_$_seq';
  }

  // The rest of the contract is not used by these tests; throw if called.
  @override
  Future<void> deleteImage(String guid) => throw UnimplementedError();

  @override
  Future<ImageRef?> getImage(String guid, {bool verifyExists = false}) =>
      throw UnimplementedError();

  @override
  Future<void> deleteAllImages() {
    // TODO: implement deleteAllImages
    throw UnimplementedError();
  }

  @override
  Future<void> init() {
    // TODO: implement init
    throw UnimplementedError();
  }

  @override
  // TODO: implement isInitialized
  bool get isInitialized => throw UnimplementedError();
}

/// ---------------------------------------------------------------------------
/// Harness VM to expose the mixin and capture update callbacks
/// ---------------------------------------------------------------------------

class _HarnessVm extends ChangeNotifier with ImageEditingMixin {
  int updates = 0;
  ImageSet? lastImageSet;

  void configure({required IImageDataService store, required ITemporaryFileService temps}) {
    configureImageEditing(
      imageStore: store,
      tempFiles: temps,
      updateImages: ({required images, bool notify = true}) {
        updates++;
        lastImageSet = images;
        if (notify) notifyListeners();
      },
    );
  }
}

void main() {
  group('ImageEditingMixin', () {
    test('startImageSession sets session and notifies', () async {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      var ticks = 0;
      vm.addListener(() => ticks++);

      expect(vm.hasTempSession, isFalse);

      await vm.startImageSession('test_session');

      expect(vm.hasTempSession, isTrue);
      expect(files.lastSession, isNotNull);
      expect(files.lastSession!.label, 'test_session');
      expect(ticks, 1);
    });

    test('disposeImageSession disposes and clears session; notify optional', () async {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      await vm.startImageSession('x');
      final s = files.lastSession as _FakeTempSession;

      var ticks = 0;
      vm.addListener(() => ticks++);

      // No notify by default
      await vm.disposeImageSession();
      expect(vm.hasTempSession, isFalse);
      expect(s.disposed, isTrue);
      expect(ticks, 0);

      // Start again, then notify on dispose
      await vm.startImageSession('y');
      final s2 = files.lastSession as _FakeTempSession;
      await vm.disposeImageSession(notify: true);
      expect(vm.hasTempSession, isFalse);
      expect(s2.disposed, isTrue);
      expect(ticks, 2);
    });

    test('seedExistingImages builds ids + refs in order and calls update', () {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      final guids = ['a', 'b', 'c'];
      ImageSet imageSet = ImageSet.fromGuids(store, guids);
      vm.seedExistingImages(imageSet);

      expect(vm.lastImageSet, isNotNull);
      expect(vm.updates, 1);
      expect(vm.lastImageSet!.refs.length, 3);
      expect(vm.lastImageSet!.ids.length, 3);

      // Types: persisted ids for all
      for (final id in vm.lastImageSet!.ids) {
        expect(id, isA<PersistedImageIdentifier>());
      }

      // Refs are created via refForGuid
      final refs = vm.lastImageSet!.refs;
      expect((refs[0] as AssetImageRef).assetName, 'assets/a.png');
      expect((refs[1] as AssetImageRef).assetName, 'assets/b.png');
      expect((refs[2] as AssetImageRef).assetName, 'assets/c.png');
    });

    test('onImagePicked appends and update lists are unmodifiable to callers', () {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      final tmpFile = File('${Directory.systemTemp.path}/x.jpg');
      final tmpId = TempImageIdentifier(tmpFile);
      final ref = ImageRef.file(tmpFile.path);

      vm.onImagePicked(tmpId, ref);

      expect(vm.updates, 1);
      expect(vm.lastImageSet!.ids.single, same(tmpId));
      expect(vm.lastImageSet!.refs.single, same(ref));

      // The lists passed to the callback are unmodifiable
      expect(() => vm.lastImageSet!.refs.add(ref), throwsUnsupportedError);
      expect(() => vm.lastImageSet!.ids.add(tmpId), throwsUnsupportedError);
    });

    test('onRemoveAt removes aligned entries; OOB is no-op', () {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      // Seed three persisted images
      ImageSet imageSet = ImageSet.fromGuids(store, ['g1', 'g2', 'g3']);
      vm.seedExistingImages(imageSet);
      final beforeUpdates = vm.updates;

      // Remove middle one
      vm.onRemoveAt(1);
      expect(vm.updates, beforeUpdates + 1);
      final lastIds = vm.lastImageSet!.ids;
      expect(lastIds.length, 2);
      expect((lastIds[0] as PersistedImageIdentifier).guid, 'g1');
      expect((lastIds[1] as PersistedImageIdentifier).guid, 'g3');

      // OOB (no crash, no update)
      vm.onRemoveAt(99);
      expect(vm.updates, beforeUpdates + 1);
    });

    test('persistImageGuids converts temps to persisted and preserves order; no notify', () async {
      final vm = _HarnessVm();
      final files = _FakeTemporaryFileService();
      final store = _FakeImageDataService();
      vm.configure(store: store, temps: files);

      // Start with one persisted
      ImageSet imageSet = ImageSet.fromGuids(store, ['keep_me']);
      vm.seedExistingImages(imageSet);

      // Add two temps via onImagePicked
      final f1 = File('${Directory.systemTemp.path}/t1.jpg');
      final f2 = File('${Directory.systemTemp.path}/t2.jpg');

      vm.onImagePicked(TempImageIdentifier(f1), ImageRef.file(f1.path));
      vm.onImagePicked(TempImageIdentifier(f2), ImageRef.file(f2.path));

      // Track notifications around persist
      var ticks = 0;
      vm.addListener(() => ticks++);

      final guids = await vm.persistImageGuids(deleteTempOnSuccess: true);

      // No notify from persist itself
      expect(ticks, 0);

      // Should return 3 guids in UI order
      expect(guids.length, 3);
      expect(guids[0], 'keep_me'); // already persisted
      expect(guids[1], startsWith('guid_')); // newly saved
      expect(guids[2], startsWith('guid_'));

      // Internal ids converted to PersistedImageIdentifier where needed
      final imageIds = vm.images.ids;
      expect((imageIds[0] as PersistedImageIdentifier).guid, 'keep_me');
      expect(imageIds[1], isA<PersistedImageIdentifier>());
      expect(imageIds[2], isA<PersistedImageIdentifier>());

      // Image store called for the two temp files
      expect(store.savedFiles.length, 2);
      expect(store.savedFiles.map((f) => f.path), containsAll([f1.path, f2.path]));
      expect(store.deleteFlags, everyElement(isTrue)); // deleteTempOnSuccess=true
    });
  });
}
