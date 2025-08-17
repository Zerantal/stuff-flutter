// test/shared/image/image_picker_controller_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:stuff/shared/image/image_picker_controller.dart';
import 'package:stuff/shared/image/pick_result.dart';
import 'package:stuff/services/contracts/image_picker_service_interface.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/services/contracts/temporary_file_service_interface.dart';
import 'package:stuff/shared/image/image_ref.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakePicker implements IImagePickerService {
  File? galleryFile;
  File? cameraFile;
  Object? galleryError;
  Object? cameraError;

  @override
  Future<File?> pickImageFromGallery({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (galleryError != null) throw galleryError!;
    return galleryFile;
  }

  @override
  Future<File?> pickImageFromCamera({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    if (cameraError != null) throw cameraError!;
    return cameraFile;
  }
}

class _FakeStore extends IImageDataService {
  bool _initialized = true;
  bool shouldThrowOnSave = false;
  String guidToReturn = 'guid-123';
  File? lastSavedFile;
  bool? lastDeleteSource;

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  bool get isInitialized => _initialized;

  @override
  Future<ImageRef?> getImage(String imageGuid, {bool verifyExists = true}) async {
    // Not needed in these tests
    return null;
  }

  // IMPORTANT: new controller calls saveImage with {deleteSource: true}
  @override
  Future<String> saveImage(File imageFile, {bool deleteSource = false}) async {
    if (shouldThrowOnSave) {
      throw Exception('save failed');
    }
    lastSavedFile = imageFile;
    lastDeleteSource = deleteSource;
    if (deleteSource) {
      try {
        await imageFile.delete();
      } catch (_) {
        // ignore
      }
    }
    return guidToReturn;
  }

  @override
  Future<void> deleteImage(String imageGuid) async {}

  @override
  Future<void> deleteAllImages() async {}

  @override
  ImageRef refForGuid(String imageGuid) {
    // not needed for these tests
    throw UnimplementedError();
  }
}

class _FakeTempSession implements TempSession {
  _FakeTempSession(this._dir);
  final Directory _dir;

  @override
  Directory get dir => _dir;

  @override
  Future<File> importFile(File src, {String? preferredName, bool deleteSource = false}) async {
    if (!await _dir.exists()) {
      await _dir.create(recursive: true);
    }
    final base = (preferredName == null || preferredName.trim().isEmpty)
        ? p.basename(src.path)
        : p.basename(preferredName);
    var dest = File(p.join(_dir.path, base));

    // ensure unique filename if exists
    if (await dest.exists()) {
      final name = p.basenameWithoutExtension(base);
      final ext = p.extension(base);
      var i = 1;
      while (await dest.exists()) {
        dest = File(p.join(_dir.path, '$name-$i$ext'));
        i++;
      }
    }

    if (deleteSource) {
      try {
        await src.rename(dest.path);
        return dest;
      } catch (_) {
        // fall back to copy+delete
        await src.copy(dest.path);
        try {
          await src.delete();
        } catch (_) {}
        return dest;
      }
    } else {
      await src.copy(dest.path);
      return dest;
    }
  }

  @override
  Future<void> dispose({bool deleteContents = true}) async {
    if (deleteContents && await _dir.exists()) {
      await _dir.delete(recursive: true);
    }
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<File> _makeTempFile(Directory where, String name, {int bytes = 32}) async {
  final f = File(p.join(where.path, name));
  await f.create(recursive: true);
  await f.writeAsBytes(List<int>.generate(bytes, (i) => i % 256));
  return f;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory sandbox;
  late _FakePicker picker;
  late _FakeStore store;
  late _FakeTempSession session;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    sandbox = await Directory.systemTemp.createTemp('img_pick_ctrl_test_');
    picker = _FakePicker();
    store = _FakeStore();
    session = _FakeTempSession(Directory(p.join(sandbox.path, 'session')));
  });

  tearDown(() async {
    try {
      if (await sandbox.exists()) {
        await sandbox.delete(recursive: true);
      }
    } catch (_) {}
  });

  test('pickFromGallery returns PickCancelled when user cancels', () async {
    picker.galleryFile = null;

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: false,
    );

    final r = await controller.pickFromGallery();
    expect(r, isA<PickCancelled>());
  });

  test('pickFromGallery stages a temp file when not eagerPersist', () async {
    final src = await _makeTempFile(sandbox, 'camera/original.jpg');
    picker.galleryFile = src;

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: false,
    );

    final r = await controller.pickFromGallery();
    expect(r, isA<PickedTemp>());
    final staged = (r as PickedTemp).file;

    expect(await staged.exists(), isTrue);
    expect(p.isWithin(session.dir.path, staged.path), isTrue);
    // Original remains since deleteSource=false during staging
    expect(await src.exists(), isTrue);
  });

  test('pickFromCamera eagerPersist=true saves and returns SavedGuid', () async {
    final src = await _makeTempFile(sandbox, 'cam/take.jpg');
    picker.cameraFile = src;
    store.guidToReturn = 'g-001';

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: true,
    );

    final r = await controller.pickFromCamera();
    expect(r, isA<SavedGuid>());
    expect((r as SavedGuid).guid, equals('g-001'));

    // Store saw deleteSource=true (so staged file would have been removed)
    expect(store.lastDeleteSource, isTrue);

    // Session directory should be empty if saveImage deleted the staged file.
    final exists = await session.dir.exists();
    if (exists) {
      final entries = await session.dir.list(followLinks: false).toList();
      expect(entries.isEmpty, isTrue);
    }
  });

  test('pickFromCamera eagerPersist=true but save fails -> falls back to PickedTemp', () async {
    final src = await _makeTempFile(sandbox, 'cam/fail.jpg');
    picker.cameraFile = src;
    store.shouldThrowOnSave = true;

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: true,
    );

    final r = await controller.pickFromCamera();
    expect(r, isA<PickedTemp>());

    final staged = (r as PickedTemp).file;
    expect(await staged.exists(), isTrue);
    expect(p.isWithin(session.dir.path, staged.path), isTrue);
  });

  test('persistTemp succeeds and deletes source', () async {
    // First stage a file (not eager)
    final src = await _makeTempFile(sandbox, 'g/persist_me.png');
    picker.galleryFile = src;

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: false,
    );

    final r1 = await controller.pickFromGallery();
    expect(r1, isA<PickedTemp>());
    final staged = (r1 as PickedTemp).file;

    final r2 = await controller.persistTemp(staged);
    expect(r2, isA<SavedGuid>());
    expect(store.lastSavedFile?.path, equals(staged.path));
    expect(store.lastDeleteSource, isTrue);
    expect(await staged.exists(), isFalse); // deleted by store on success
  });

  test('persistTemp fails -> PickFailed and staged file remains', () async {
    final src = await _makeTempFile(sandbox, 'g/persist_fail.png');
    picker.galleryFile = src;
    store.shouldThrowOnSave = true;

    final controller = ImagePickerController(
      picker: picker,
      session: session,
      store: store,
      eagerPersist: false,
    );

    final r1 = await controller.pickFromGallery();
    final staged = (r1 as PickedTemp).file;

    final r2 = await controller.persistTemp(staged);
    expect(r2, isA<PickFailed>());
    expect(await staged.exists(), isTrue); // store did not delete on failure
  });
}
