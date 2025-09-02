import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/room/viewmodels/edit_room_view_model.dart';
import 'package:stuff/domain/models/room_model.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/core/image_identifier.dart';

import '../../../utils/mocks.dart';

void main() {
  group('EditRoomViewModel', () {
    late MockIDataService data;
    late MockIImageDataService images;
    late MockITemporaryFileService tempFiles;
    late MockTempSession mockSession;

    setUp(() {
      data = MockIDataService();
      images = MockIImageDataService();
      tempFiles = MockITemporaryFileService();
      mockSession = MockTempSession();

      when(tempFiles.startSession(label: anyNamed('label'))).thenAnswer((_) async => mockSession);
    });

    test('init() - create mode - starts temp session, ends initialising', () async {
      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );

      expect(vm.isInitialised, isFalse); // default true
      await vm.initForNew();

      // Session created, flag set, initialising false
      verify(
        tempFiles.startSession(label: argThat(startsWith('add_room_L1'), named: 'label')),
      ).called(1);
      expect(vm.hasTempSession, isTrue);
      expect(vm.isInitialised, isTrue);
      expect(vm.isNewRoom, isTrue);
    });

    test('init() - edit mode: loads room, populates controllers, sets isNewRoom=false', () async {
      when(data.getRoomById('R1')).thenAnswer(
        (_) async => Room(
          id: 'R1',
          locationId: 'L1',
          name: 'Garage',
          description: 'tools',
          imageGuids: const [],
        ),
      );

      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );

      await vm.initForEdit('R1');

      verify(data.getRoomById('R1')).called(1);
      verify(
        tempFiles.startSession(label: argThat(startsWith('edit_room_L1_R1'), named: 'label')),
      ).called(1);

      expect(vm.isNewRoom, isFalse);
      expect(vm.nameController.text, 'Garage');
      expect(vm.currentState.description, 'tools');
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.isInitialised, isTrue);
    });

    test('typing in text fields flips hasUnsavedChanges and notifies listeners', () async {
      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );
      await vm.initForNew();

      var notified = 0;
      vm.addListener(() => notified++);

      vm.nameController.text = 'Kitchen';
      vm.descriptionController.text = 'Downstairs';
      expect(vm.hasUnsavedChanges, isTrue);
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('onImagePicked / removeImage updates images and marks dirty', () async {
      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );
      await vm.initForNew();

      expect(vm.currentState.images, isEmpty);

      // Pick one temp image
      vm.onImagePicked(
        TempImageIdentifier(File('/tmp/pic.png')),
        const ImageRef.asset('assets/x.png'),
      );
      expect(vm.currentState.images.length, 1);
      expect(vm.hasUnsavedChanges, isTrue);

      // Remove it
      vm.onRemoveAt(0);
      expect(vm.currentState.images, isEmpty);
      expect(vm.hasUnsavedChanges, isFalse);
    });

    test('dispose() disposes temp session', () async {
      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );
      await vm.initForNew();
      vm.dispose();

      verify(mockSession.dispose()).called(1);
    });

    testWidgets('saveRoom returns false immediately if already saving OR form invalid', (
      tester,
    ) async {
      final vm = EditRoomViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
        locationId: 'L1',
      );
      await vm.initForNew();

      // Case 1: already saving
      // (flip internal state via copyWith through public `state` would be brittle;
      // instead, call saveRoom and immediately call again)
      final first = vm.saveState(); // kicks off
      final second = await vm.saveState(); // should bail
      expect(second, isFalse);
      await first;

      // Case 2: with a real Form that fails validation
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Form(
              key: vm.formKey,
              child: TextFormField(
                controller: vm.nameController.raw,
                validator: (_) => 'err', // force invalid
              ),
            ),
          ),
        ),
      );
      final ok = await vm.saveState();
      expect(ok, isFalse);
    });
  });
}
