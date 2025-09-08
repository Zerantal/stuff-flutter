// test/shared/image/image_identifier_to_ref_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/shared/image/image_identifier_to_ref.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';

import '../../utils/mocks.dart';

import '../../utils/dummies.dart';

@GenerateMocks([IImageDataService])
void main() {
  group('toImageRefSync', () {
    late MockIImageDataService store;

    setUp(() {
      store = MockIImageDataService();
      registerCommonDummies();
    });

    test('GuidIdentifier → uses store.refForGuid', () {
      final expected = const ImageRef.file('/path/from/store');
      when(store.refForGuid('G1')).thenReturn(expected);

      final ref = toImageRefSync(PersistedImageIdentifier('G1'), store);

      expect(ref, same(expected));
      verify(store.refForGuid('G1')).called(1);
    });

    test('TempFileIdentifier → ImageRef.file', () {
      final file = File('/tmp/a.png');
      final ref = toImageRefSync(TempImageIdentifier(file), store);

      expect(ref, isNotNull);
    });

    test('toImageRefs returns one ref per input (verifyExists: false)', () async {
      when(store.refForGuid(any)).thenReturn(const ImageRef.file('/from/store'));

      final list = [PersistedImageIdentifier('G'), TempImageIdentifier(File('/tmp/x.png'))];

      final refs = await toImageRefs(list, store, verifyExists: false);

      expect(refs.length, list.length);
    });

    test('empty list → empty refs', () async {
      final refs = await toImageRefs([], store, verifyExists: false);
      expect(refs, isEmpty);
    });
  });

  group('async methods with verifyExists', () {
    late MockIImageDataService store;

    setUp(() {
      store = MockIImageDataService();
      registerCommonDummies();
    });

    test('toImageRef: PersistedImageIdentifier calls store.getImage', () async {
      final expected = const ImageRef.file('/from/getImage');
      when(store.getImage('G1', verifyExists: true)).thenAnswer((_) async => expected);

      final ref = await toImageRef(PersistedImageIdentifier('G1'), store, verifyExists: true);

      expect(ref, same(expected));
      verify(store.getImage('G1', verifyExists: true)).called(1);
    });

    test('toImageRef: TempImageIdentifier returns FileImageRef', () async {
      final file = File('/tmp/x.png');
      final ref = await toImageRef(TempImageIdentifier(file), store, verifyExists: true);

      expect(ref, isA<FileImageRef>());
      expect((ref as FileImageRef).path, file.path);
      verifyNever(store.getImage(any, verifyExists: anyNamed('verifyExists')));
    });

    test('toImageRefs: multiple identifiers with verifyExists=true', () async {
      final expected = const ImageRef.file('/from/getImage');
      when(store.getImage(any, verifyExists: true)).thenAnswer((_) async => expected);

      final list = [PersistedImageIdentifier('G1'), TempImageIdentifier(File('/tmp/x.png'))];

      final refs = await toImageRefs(list, store, verifyExists: true);

      // Both should have produced refs
      expect(refs.length, 2);
      expect(refs.any((r) => r is FileImageRef), isTrue);
      expect(refs.any((r) => r == expected), isTrue);
      verify(store.getImage('G1', verifyExists: true)).called(1);
    });
  });
}
