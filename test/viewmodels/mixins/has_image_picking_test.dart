// test/viewmodels/mixins/has_image_picking_test.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import "package:stuff/viewmodels/mixins/has_image_picking.dart";
import 'package:stuff/image/image_picker_controller.dart';
import 'package:stuff/image/pick_result.dart';

class _MockController extends Mock implements ImagePickerController {}

class _Vm with ChangeNotifier, HasImagePicking {
  _Vm(ImagePickerController controller) {
    imagePicker = controller;
  }
}

void main() {
  late _MockController controller;
  late _Vm vm;
  late int notifyCount;

  setUp(() {
    controller = _MockController();
    vm = _Vm(controller);
    notifyCount = 0;
    vm.addListener(() => notifyCount++);
  });

  test(
    'busy flag toggles true -> false on success, with two notifications',
    () async {
      final completer = Completer<PickResult>();

      when(
        () => controller.pickFromGallery(),
      ).thenAnswer((_) => completer.future);

      final future = vm.pickFromGallery();

      // Allow the microtask that flips the flag to run.
      await Future<void>.delayed(Duration.zero);
      expect(vm.isPickingImage, isTrue);
      expect(notifyCount, 1);

      completer.complete(PickedTemp(File('/tmp/example.jpg')));
      final result = await future;
      expect(result, isA<PickedTemp>());
      expect(vm.isPickingImage, isFalse);
      expect(notifyCount, 2);

      verify(() => controller.pickFromGallery()).called(1);
      verifyNoMoreInteractions(controller);
    },
  );

  test('busy flag toggles true -> false on cancel', () async {
    final completer = Completer<PickResult>();
    when(() => controller.pickFromCamera()).thenAnswer((_) => completer.future);

    final future = vm.pickFromCamera();
    await Future<void>.delayed(Duration.zero);
    expect(vm.isPickingImage, isTrue);
    expect(notifyCount, 1);

    completer.complete(const PickCancelled());
    final result = await future;
    expect(result, isA<PickCancelled>());
    expect(vm.isPickingImage, isFalse);
    expect(notifyCount, 2);

    verify(() => controller.pickFromCamera()).called(1);
    verifyNoMoreInteractions(controller);
  });

  test('busy flag resets to false even when controller throws', () async {
    when(
      () => controller.pickFromGallery(),
    ).thenAnswer((_) async => throw StateError('boom'));

    // Start the operation; it will error.
    expectLater(vm.pickFromGallery(), throwsA(isA<StateError>()));

    // Give the future a chance to start and then complete with error.
    await Future<void>.delayed(const Duration(milliseconds: 10));

    // After error, flag must be false and we should have two notifications.
    expect(vm.isPickingImage, isFalse);
    expect(notifyCount, 2);

    verify(() => controller.pickFromGallery()).called(1);
  });

  test(
    'second call while busy returns PickFailed(StateError("Busy")) and does not call controller',
    () async {
      final gate = Completer<PickResult>();
      when(() => controller.pickFromGallery()).thenAnswer((_) => gate.future);

      // Kick off first call (goes busy)
      final first = vm.pickFromGallery();
      await Future<void>.delayed(Duration.zero);
      expect(vm.isPickingImage, isTrue);

      // While busy, issue another call
      final second = await vm.pickFromCamera();
      expect(second, isA<PickFailed>());
      final pf = second as PickFailed;
      expect(pf.error, isA<StateError>());

      // Ensure controller.pickFromCamera was never invoked
      verifyNever(() => controller.pickFromCamera());

      // Finish the first op and ensure we reset
      gate.complete(const PickCancelled());
      await first;
      expect(vm.isPickingImage, isFalse);
    },
  );
}
