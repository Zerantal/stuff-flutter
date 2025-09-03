// test/features/location/viewmodels/edit_location_view_model_test.dart
// ignore_for_file: INVALID_USE_OF_PROTECTED_MEMBER

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/location/viewmodels/edit_location_view_model.dart';
import 'package:stuff/features/location/state/edit_location_state.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/features/shared/state/image_set.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/core/image_identifier.dart';

import '../../../utils/mocks.dart';
import '../../../utils/dummies.dart';

Location _loc({
  String? id,
  String name = 'Office',
  String? description = 'Desc',
  String? address = '123 Main',
  List<String> guids = const [],
}) =>
    Location(
      id: id,
      name: name,
      description: description,
      address: address,
      imageGuids: guids,
    );

void main() {
  group('EditLocationViewModel (Mockito)', () {
    late MockIDataService data;
    late MockIImageDataService images;
    late MockITemporaryFileService temps;
    late MockTempSession session;
    late MockILocationService locSvc;
    late EditLocationViewModel vm;

    setUp(() {
      data = MockIDataService();
      images = MockIImageDataService();
      temps = MockITemporaryFileService();
      session = MockTempSession();
      locSvc = MockILocationService();

      registerCommonDummies();

      when(temps.startSession(label: anyNamed('label')))
          .thenAnswer((_) async => session);

      // Default upsert returns what was passed in (with id set if null)
      when(data.upsertLocation(any)).thenAnswer((inv) async {
        final m = inv.positionalArguments.first as Location;
        return m.withTouched();
      });

      vm = EditLocationViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: temps,
        locationService: locSvc,
      );
    });

    test('initForNew → seeds empty state, starts session, imageListRevision=0', () async {
      var ticks = 0;
      vm.addListener(() => ticks++);

      await vm.initForNew();

      expect(vm.isInitialised, isTrue);
      expect(vm.isNewLocation, isTrue);
      expect(vm.initialLoadError, isNull);
      expect(vm.currentState, isA<EditLocationState>());
      expect(vm.currentState.images.ids, isEmpty);
      expect(vm.imageListRevision, 0);

      verify(temps.startSession(label: argThat(startsWith('add_loc'), named: 'label')))
          .called(1);
      expect(ticks, greaterThanOrEqualTo(1));
    });

    test('initForEdit success → loads model, seeds images (revision++), starts session', () async {
      when(data.getLocationById('L1'))
          .thenAnswer((_) async => _loc(id: 'L1', name: 'Garage', guids: ['a', 'b', 'c']));

      await vm.initForEdit('L1');

      expect(vm.isNewLocation, isFalse);
      expect(vm.isInitialised, isTrue);
      expect(vm.currentState.name, 'Garage');
      expect(vm.currentState.images.length, 3);
      expect(vm.imageListRevision, 1, reason: 'seedExistingImages -> updateImages -> ++');

      verify(temps.startSession(label: argThat(startsWith('edit_loc'), named: 'label')))
          .called(1);
      verify(data.getLocationById('L1')).called(1);
      verify(images.refForGuid(any)).called(3);
    });

    test('initForEdit failure → sets initialLoadError and stays uninitialised', () async {
      when(data.getLocationById('missing')).thenThrow(StateError('boom'));

      await vm.initForEdit('missing');

      expect(vm.isInitialised, isFalse);
      expect(vm.initialLoadError, isA<StateError>());
      verifyNever(temps.startSession(label: anyNamed('label')));
    });

    test('controllers update state after initForNew', () async {
      await vm.initForNew();

      vm.nameController.text = 'NameX';
      vm.descriptionController.text = 'DescY';
      vm.addressController.text = 'AddrZ';

      expect(vm.currentState.name, 'NameX');
      expect(vm.currentState.description, 'DescY');
      expect(vm.currentState.address, 'AddrZ');
    });

    test('onAcquiredAddress updates state and controller (silent)', () async {
      await vm.initForNew();

      vm.onAcquiredAddress('42 Wallaby Way');
      expect(vm.currentState.address, '42 Wallaby Way');
      expect(vm.addressController.text, '42 Wallaby Way');
    });

    test('imageListRevision bumps on onImagePicked and onRemoveAt', () async {
      await vm.initForNew();

      final start = vm.imageListRevision;

      final f1 = File('${Directory.systemTemp.path}/tmp_1.jpg');
      vm.onImagePicked(TempImageIdentifier(f1), ImageRef.file(f1.path));
      expect(vm.imageListRevision, start + 1);

      vm.onRemoveAt(0);
      expect(vm.imageListRevision, start + 2);

      // OOB: no change
      vm.onRemoveAt(999);
      expect(vm.imageListRevision, start + 2);
    });

    test('saveState persists temps, upserts, normalizes ids, bumps revision once', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Two sequential GUIDs returned by saveImage
      var seq = 0;
      when(images.saveImage(any, deleteSource: anyNamed('deleteSource')))
          .thenAnswer((_) async => 'guid_${++seq}');

      await vm.initForNew();

      // Seed one persisted GUID, then add two temps
      ImageSet imageSet = ImageSet.fromGuids(images, ['keep_me']);
      vm.seedExistingImages(imageSet); // revision++ inside updateImages
      final revAfterSeed = vm.imageListRevision;

      final f1 = File('${Directory.systemTemp.path}/t1.jpg');
      final f2 = File('${Directory.systemTemp.path}/t2.jpg');
      vm.onImagePicked(TempImageIdentifier(f1), ImageRef.file(f1.path));
      vm.onImagePicked(TempImageIdentifier(f2), ImageRef.file(f2.path));

      final ok = await vm.saveState();
      expect(ok, isTrue);

      // normalize step in onSaveState -> revision++
      expect(vm.imageListRevision, revAfterSeed + 3); // 1(seed)+2(picks)+1(normalize) == +4 total

      // Upsert called with 3 guids in UI order: keep_me, guid_1, guid_2
      var verification = verify(data.upsertLocation(captureAny));
      verification.called(1);
      final saved = verification.captured.single as Location;
      expect(saved.imageGuids, ['keep_me', 'guid_1', 'guid_2']);

      // Two saves were performed for the temp files
      verify(images.saveImage(any, deleteSource: true)).called(2);
      verifyNever(images.deleteImage(any));
    });

    test('orphan cleanup deletes removed persisted images on save', () async {
      when(data.getLocationById('Lx'))
          .thenAnswer((_) async => _loc(id: 'Lx', name: 'N', guids: ['a', 'b']));

      await vm.initForEdit('Lx');

      // Remove 'b' before save
      vm.onRemoveAt(1);

      await vm.saveState();

      verify (images.deleteImage(any)).called(1);
      verify(data.upsertLocation(any)).called(1);
    });

    test('retryInitForEdit clears error then succeeds', () async {
      when(data.getLocationById('Z')).thenThrow(Exception('first-fail'));

      await vm.initForEdit('Z');
      expect(vm.initialLoadError, isNotNull);
      expect(vm.isInitialised, isFalse);

      // Next try succeeds
      reset(data);
      when(data.getLocationById('Z'))
          .thenAnswer((_) async => _loc(id: 'Z', name: 'Loaded', guids: const []));
      when(temps.startSession(label: anyNamed('label')))
          .thenAnswer((_) async => session);

      await vm.retryInitForEdit('Z');
      expect(vm.initialLoadError, isNull);
      expect(vm.isInitialised, isTrue);
      expect(vm.currentState.name, 'Loaded');
    });
  });
}
