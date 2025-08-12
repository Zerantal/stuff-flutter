// test/image/image_picker_controller_test.dart
// NOTE: Adjust the 'package:stuff/...' imports to match your real package name.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:stuff/image/image_picker_controller.dart';
import 'package:stuff/image/pick_result.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import 'package:stuff/services/image_picker_service_interface.dart';
import 'package:stuff/services/temporary_file_service_interface.dart';

class _MockPicker extends Mock implements IImagePickerService {}

class _MockStore extends Mock implements IImageDataService {}

class _MockTemp extends Mock implements ITemporaryFileService {}

/// Simple duck-typed stand-in for XFile; controller only needs a `.path`.
class _FakeFile extends Fake implements File {
  _FakeFile(this.path);

  @override
  late final String path;
}

void main() {
  late _MockPicker picker;
  late _MockStore store;
  late _MockTemp temp;

  setUpAll(() {
    registerFallbackValue(File('fallback.tmp'));
  });

  setUp(() {
    picker = _MockPicker();
    store = _MockStore();
    temp = _MockTemp();
  });

  group('pickFromGallery / pickFromCamera', () {
    test('returns PickCancelled when picker yields null', () async {
      when(() => picker.pickImageFromGallery()).thenAnswer((_) async => null);

      final c = ImagePickerController(picker: picker);

      final r = await c.pickFromGallery();
      expect(r, isA<PickCancelled>());
      verify(() => picker.pickImageFromGallery()).called(1);
      verifyNoMoreInteractions(picker);
    });

    test('stages to temp and runs processor', () async {
      final src = File('/tmp/source.jpg');
      final staged = File('/tmp/staged.jpg');
      final processed = File('/tmp/processed.jpg');

      when(() => picker.pickImageFromGallery()).thenAnswer((_) async => src);
      when(() => temp.copyToTemp(src)).thenAnswer((_) async => staged);

      var called = false;
      Future<File> processor(File f) async {
        called = true;
        expect(f.path, staged.path); // processor sees the staged file
        return processed;
      }

      final c = ImagePickerController(
        picker: picker,
        temp: temp,
        processor: processor,
      );

      final r = await c.pickFromGallery();
      expect(r, isA<PickedTemp>());
      expect((r as PickedTemp).file.path, processed.path);
      expect(called, isTrue);

      verify(() => picker.pickImageFromGallery()).called(1);
      verify(() => temp.copyToTemp(src)).called(1);
      verifyNoMoreInteractions(picker);
      verifyNoMoreInteractions(temp);
    });

    test('falls back to original file when temp.copyToTemp throws', () async {
      final src = File('/tmp/source.jpg');
      final processed = File('/tmp/processed.jpg');

      when(() => picker.pickImageFromCamera()).thenAnswer((_) async => src);
      when(() => temp.copyToTemp(src)).thenThrow(Exception('disk full'));

      Future<File> processor(File f) async {
        // since staging failed, processor should see the original
        expect(f.path, src.path);
        return processed;
      }

      final c = ImagePickerController(
        picker: picker,
        temp: temp,
        processor: processor,
      );

      final r = await c.pickFromCamera();
      expect(r, isA<PickedTemp>());
      expect((r as PickedTemp).file.path, processed.path);

      verify(() => picker.pickImageFromCamera()).called(1);
      verify(() => temp.copyToTemp(src)).called(1);
      verifyNoMoreInteractions(picker);
      verifyNoMoreInteractions(temp);
    });

    test('accepts duck-typed XFile with .path', () async {
      final fake = _FakeFile('/tmp/fake-file.jpg');

      // Even if your real service returns XFile, controller will accept due to .path
      when(() => picker.pickImageFromGallery()).thenAnswer((_) async => fake);

      final c = ImagePickerController(picker: picker);

      final r = await c.pickFromGallery();
      expect(r, isA<PickedTemp>());
      expect((r as PickedTemp).file.path, fake.path);
    });
  });

  group('persistTemp', () {
    test('returns SavedGuid on success', () async {
      final f = File('/tmp/to-save.jpg');
      when(() => store.saveImage(f)).thenAnswer((_) async => 'guid-123');

      final c = ImagePickerController(picker: picker, store: store);

      final r = await c.persistTemp(f);
      expect(r, isA<SavedGuid>());
      expect((r as SavedGuid).guid, 'guid-123');
      verify(() => store.saveImage(f)).called(1);
      verifyNoMoreInteractions(store);
    });

    test('returns PickFailed when store throws', () async {
      final f = File('/tmp/to-save.jpg');
      when(() => store.saveImage(f)).thenThrow(StateError('oops'));

      final c = ImagePickerController(picker: picker, store: store);

      final r = await c.persistTemp(f);
      expect(r, isA<PickFailed>());
      final pf = r as PickFailed;
      expect(pf.error, isA<StateError>());
      verify(() => store.saveImage(f)).called(1);
    });
  });

  group('end-to-end helpers', () {
    test('pickFromGalleryAndPersist chains success path', () async {
      final src = File('/tmp/source.jpg');
      final staged = File('/tmp/staged.jpg');

      when(() => picker.pickImageFromGallery()).thenAnswer((_) async => src);
      when(() => temp.copyToTemp(src)).thenAnswer((_) async => staged);
      when(() => store.saveImage(staged)).thenAnswer((_) async => 'g-001');

      final c = ImagePickerController(picker: picker, temp: temp, store: store);

      final r = await c.pickFromGalleryAndPersist();
      expect(r, isA<SavedGuid>());
      expect((r as SavedGuid).guid, 'g-001');

      verify(() => picker.pickImageFromGallery()).called(1);
      verify(() => temp.copyToTemp(src)).called(1);
      verify(() => store.saveImage(staged)).called(1);
    });

    test('pickFromCameraAndPersist passes through cancel', () async {
      when(() => picker.pickImageFromCamera()).thenAnswer((_) async => null);

      final c = ImagePickerController(picker: picker, temp: temp, store: store);

      final r = await c.pickFromCameraAndPersist();
      expect(r, isA<PickCancelled>());
      verify(() => picker.pickImageFromCamera()).called(1);
      verifyZeroInteractions(temp);
      verifyZeroInteractions(store);
    });
  });
}
