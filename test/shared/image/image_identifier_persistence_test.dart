// test/shared/image/image_identifier_persistence_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/shared/image/image_identifier_persistence.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';

import '../../utils/mocks.dart';

@GenerateMocks([IImageDataService])
void main() {
  group('ensureGuids', () {
    late MockIImageDataService store;

    setUp(() {
      store = MockIImageDataService();
    });

    test('returns existing GUIDs unchanged and persists temp files (order preserved)', () async {
      // Arrange: mix of existing guid + temp files + existing guid
      final id1 = GuidIdentifier('G1');
      final temp1 = TempFileIdentifier(File('/tmp/a.png'));
      final temp2 = TempFileIdentifier(File('/tmp/b.png'));
      final id2 = GuidIdentifier('G2');

      int c = 0;
      when(
        store.saveImage(any, deleteSource: anyNamed('deleteSource')),
      ).thenAnswer((_) async => 'X${c++}');

      // Act
      final result = await persistTempImages(
        [id1, temp1, temp2, id2],
        store,
        deleteTempOnSuccess: true,
      );

      // Assert
      expect(result, ['G1', 'X0', 'X1', 'G2']);
      verify(store.saveImage(argThat(isA<File>()), deleteSource: true)).called(2);
      verifyNoMoreInteractions(store);
    });

    test('no temp files → does not call saveImages', () async {
      final ids = [GuidIdentifier('A'), GuidIdentifier('B')];

      final result = await persistTempImages(ids, store);

      expect(result, ['A', 'B']);
      verifyZeroInteractions(store);
    });

    test('works with single temp file at start or end', () async {
      when(
        store.saveImage(any, deleteSource: anyNamed('deleteSource')),
      ).thenAnswer((_) async => 'X');

      final res1 = await persistTempImages([
        TempFileIdentifier(File('/tmp/only.png')),
        GuidIdentifier('Z'),
      ], store);
      expect(res1, ['X', 'Z']);

      final res2 = await persistTempImages([
        GuidIdentifier('Z'),
        TempFileIdentifier(File('/tmp/only.png')),
      ], store);
      expect(res2, ['Z', 'X']);
    });
  });
}
