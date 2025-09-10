// test/features/container/viewmodels/edit_container_viewmodel_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/container/viewmodels/edit_container_view_model.dart';
import 'package:stuff/domain/models/container_model.dart' as domain;
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

    test('init() - create in room - starts temp session, ends initialising', () async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );

      expect(vm.isInitialised, isFalse); // default true
      await vm.initForNew(roomId: 'R1');

      // Session created, flag set, initialising false
      verify(
        tempFiles.startSession(label: argThat(startsWith('add_contai_R1'), named: 'label')),
      ).called(1);
      expect(vm.hasTempSession, isTrue);
      expect(vm.isInitialised, isTrue);
      expect(vm.isNewContainer, isTrue);
    });

    test('init() - create in container - starts temp session, ends initialising', () async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );

      expect(vm.isInitialised, isFalse); // default true
      await vm.initForNew(parentContainerId: 'C1');

      // Session created, flag set, initialising false
      verify(
        tempFiles.startSession(label: argThat(startsWith('add_contai_C1'), named: 'label')),
      ).called(1);
      expect(vm.hasTempSession, isTrue);
      expect(vm.isInitialised, isTrue);
      expect(vm.isNewContainer, isTrue);
    });

    test('init() - create in both room and container - assertion error', () async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );

      expect(vm.isInitialised, isFalse); // default true
      expect(
        () => vm.initForNew(roomId: 'R1', parentContainerId: 'C1'),
        throwsA(isA<AssertionError>()),
      );

      expect(vm.isInitialised, isFalse); // unchanged
      expect(
        () => vm.initForNew(roomId: 'R1', parentContainerId: 'C1'),
        throwsA(isA<AssertionError>()),
      );

      expect(vm.isInitialised, isFalse); // unchanged
    });

    test('init() - edit mode: loads room, populates controllers, sets isNewRoom=false', () async {
      when(data.getContainerById('C1')).thenAnswer(
        (_) async => domain.Container(
          id: 'C1',
          roomId: 'R1',
          name: 'Garage',
          description: 'tools',
          imageGuids: const [],
        ),
      );

      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );

      await vm.initForEdit('C1');

      verify(data.getContainerById('C1')).called(1);
      verify(
        tempFiles.startSession(label: argThat(startsWith('edit_conta_C1'), named: 'label')),
      ).called(1);

      expect(vm.isNewContainer, isFalse);
      expect(vm.nameController.text, 'Garage');
      expect(vm.currentState.description, 'tools');
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.isInitialised, isTrue);
    });

    test('typing in text fields flips hasUnsavedChanges and notifies listeners', () async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );
      await vm.initForNew(roomId: 'R1');

      var notified = 0;
      vm.addListener(() => notified++);

      vm.nameController.text = 'Toolbox';
      vm.descriptionController.text = 'In Garage';
      expect(vm.hasUnsavedChanges, isTrue);
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('onImagePicked / removeImage updates images and marks dirty', () async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );
      await vm.initForNew(roomId: 'R1');

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
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );
      await vm.initForNew(roomId: 'R1');
      vm.dispose();

      verify(mockSession.dispose()).called(1);
    });

    testWidgets('saveRoom returns false immediately if already saving OR form invalid', (
      tester,
    ) async {
      final vm = EditContainerViewModel(
        dataService: data,
        imageDataService: images,
        tempFileService: tempFiles,
      );
      await vm.initForNew(roomId: 'R1');

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
