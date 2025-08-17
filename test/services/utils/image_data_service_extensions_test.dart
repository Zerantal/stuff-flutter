// test/services/contracts/image_data_service_extensions_test.dart
//
// Unit tests for ImageDataServiceConvenience extension methods on IImageDataService.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/services/utils/image_data_service_extensions.dart';
import 'package:stuff/shared/image/image_ref.dart';

import '../../utils/dummies.dart';
import '../../utils/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockIImageDataService svc;

  setUpAll(() {
    registerCommonDummies();
  });

  setUp(() {
    svc = MockIImageDataService();
  });

  group('refsForGuids', () {
    test('maps each guid via refForGuid', () {
      when(svc.refForGuid(any)).thenAnswer((inv) {
        final g = inv.positionalArguments[0] as String;
        return ImageRef.asset('mapped:$g');
      });

      final refs = svc.refsForGuids(['a', 'b', 'c']);
      expect(refs.map((r) => (r as AssetImageRef).assetName), ['mapped:a', 'mapped:b', 'mapped:c']);
      verify(svc.refForGuid('a')).called(1);
      verify(svc.refForGuid('b')).called(1);
      verify(svc.refForGuid('c')).called(1);
    });
  });

  group('deleteImages', () {
    test('calls deleteImage for each guid and swallows individual errors', () async {
      when(svc.deleteImage('bad')).thenThrow(Exception('nope'));
      when(svc.deleteImage('ok')).thenAnswer((_) async {});
      when(svc.deleteImage('fine')).thenAnswer((_) async {});

      await svc.deleteImages(['ok', 'bad', 'fine']); // extension method

      verify(svc.deleteImage('ok')).called(1);
      verify(svc.deleteImage('bad')).called(1);
      verify(svc.deleteImage('fine')).called(1);
      // No throw expected
    });
  });

  group('saveImages', () {
    test('calls saveImage for each file and returns all GUIDs', () async {
      final tmp = await Directory.systemTemp.createTemp('imgs_');
      addTearDown(() => tmp.delete(recursive: true));

      final f1 = File('${tmp.path}/1.png')..writeAsBytesSync([1]);
      final f2 = File('${tmp.path}/2.png')..writeAsBytesSync([2]);

      when(svc.saveImage(f1, deleteSource: false)).thenAnswer((_) async => 'g1');
      when(svc.saveImage(f2, deleteSource: false)).thenAnswer((_) async => 'g2');

      final guids = await svc.saveImages([f1, f2]); // extension method
      expect(guids, ['g1', 'g2']);

      verify(svc.saveImage(f1, deleteSource: false)).called(1);
      verify(svc.saveImage(f2, deleteSource: false)).called(1);
    });
  });

  group('getImages', () {
    test('resolves images and filters out nulls; forwards verifyExists', () async {
      when(
        svc.getImage('a', verifyExists: false),
      ).thenAnswer((_) async => const ImageRef.asset('a'));
      when(svc.getImage('b', verifyExists: false)).thenAnswer((_) async => null);
      when(
        svc.getImage('c', verifyExists: false),
      ).thenAnswer((_) async => const ImageRef.asset('c'));

      final refs = await svc.getImages(['a', 'b', 'c'], verifyExists: false); // extension
      expect(refs.length, 2);
      expect((refs[0] as AssetImageRef).assetName, 'a');
      expect((refs[1] as AssetImageRef).assetName, 'c');

      verify(svc.getImage('a', verifyExists: false)).called(1);
      verify(svc.getImage('b', verifyExists: false)).called(1);
      verify(svc.getImage('c', verifyExists: false)).called(1);
    });
  });
}
