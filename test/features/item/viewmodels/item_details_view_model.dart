// test/features/item/viewmodels/item_details_view_model_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/domain/models/container_model.dart' as domain;
import 'package:stuff/features/item/viewmodels/item_details_view_model.dart';

import '../../../utils/mocks.dart';
import '../../../utils/ui_runner_helper.dart';

void main() {
  group('ItemDetailsViewModel', () {
    testWidgets('initForNew throws if already initialised', (tester) async {
      await pumpWithNotifierVm<ItemDetailsViewModel>(
        tester,
        home: const SizedBox.shrink(),
        contextVmFactory: (m, ctx) => ItemDetailsViewModel.forNew(ctx, roomId: 'r1'),
        afterInit: (vm, m) async {
          // call initForNew again should throw
          expect(() => vm.retryInit(), throwsStateError);
        },
      );
    });

    testWidgets('initForNew sets roomId from container lookup', (tester) async {
      await pumpWithNotifierVm<ItemDetailsViewModel>(
        tester,
        home: const SizedBox.shrink(),
        contextVmFactory: (m, ctx) {
          when(
            m.dataService.getContainerById('c1'),
          ).thenAnswer((_) async => domain.Container(id: 'c1', roomId: 'r99', name: 'foo'));
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());

          return ItemDetailsViewModel.forNew(ctx, containerId: 'c1');
        },
        afterInit: (vm, m) async {
          await tester.pumpAndSettle();
          expect(vm.roomId, equals('r99')); // roomId populated via container
          expect(vm.isNewItem, isTrue);
          expect(vm.isInitialised, isTrue);
        },
      );
    });

    testWidgets('retryInit in item mode with null itemId throws', (tester) async {
      await pumpWithNotifierVm<ItemDetailsViewModel>(
        tester,
        home: const SizedBox.shrink(),
        vmFactory: (m) => ItemDetailsViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          tempFileService: m.temporaryFileService,
        ),
        afterInit: (vm, m) async {
          // Force init mode to item but clear itemId
          vm
            ..itemId = null
            ..isEditable = true;
          // Pretend already initialised
          expect(() => vm.retryInit(), throwsStateError);
        },
      );
    });

    testWidgets('retryInit succeeds in newItem mode', (tester) async {
      await pumpWithNotifierVm<ItemDetailsViewModel>(
        tester,
        home: const SizedBox.shrink(),
        contextVmFactory: (m, ctx) => ItemDetailsViewModel.forNew(ctx, roomId: 'r1'),
        onMocksReady: (m) {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
        },
        afterInit: (vm, m) async {
          // vm was initialised via forNew, should succeed when retrying
          await vm.retryInit();
          expect(vm.isNewItem, isTrue);
          expect(vm.roomId, equals('r1'));
        },
      );
    });

    testWidgets('retryInit throws when called before any init', (tester) async {
      await pumpWithNotifierVm<ItemDetailsViewModel>(
        tester,
        home: const SizedBox.shrink(),
        vmFactory: (m) => ItemDetailsViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          tempFileService: m.temporaryFileService,
        ),
        afterInit: (vm, m) async {
          // never initialised
          expect(() => vm.retryInit(), throwsStateError);
        },
      );
    });
  });
}
