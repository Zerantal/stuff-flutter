import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:stuff/features/contents/viewmodels/contents_view_model.dart';
import 'package:stuff/domain/models/container_model.dart' as dm;
import 'package:stuff/domain/models/item_model.dart' as dm;
import 'package:stuff/services/contracts/data_service_interface.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';

import '../../../utils/mocks.dart';
import '../../../utils/dummies.dart';
import '../../../utils/test_logger_manager.dart';

void main() {
  late MockIDataService dataService;
  late MockIImageDataService imageDataService;

  setUp(() {
    registerCommonDummies();
    dataService = MockIDataService();
    imageDataService = MockIImageDataService();
  });



  group('title/subtitle mapping', () {
    test('all scope', () {
      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.all(),
      );
      expect(vm.title, 'All Contents');
      expect(vm.subtitle, 'All containers and items');
    });

    test('location scope', () {
      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.location('L1'),
      );
      expect(vm.title, 'Location Contents');
      expect(vm.subtitle, 'Location: L1');
    });

    test('room scope', () {
      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.room('R1'),
      );
      expect(vm.title, 'Room Contents');
      expect(vm.subtitle, 'Room: R1');
    });

    test('container scope', () {
      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.container('C1'),
      );
      expect(vm.title, 'Container Contents');
      expect(vm.subtitle, 'Container: C1');
    });
  });

  group('stream wiring', () {
    test('all scope uses watchAllContainers/watchAllItems', () async {
      final c = dm.Container(id: 'C1', roomId: 'R1', name: 'Crate', imageGuids: ['g1']);
      final i = dm.Item(id: 'I1', roomId: 'R1', name: 'Item');

      when(dataService.watchAllContainers())
          .thenAnswer((_) => Stream.value([c]));
      when(dataService.watchAllItems())
          .thenAnswer((_) => Stream.value([i]));

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.all(),
      );

      final containers = await vm.containersStream.first;
      expect(containers.single.container, c);
      expect(containers.single.images, isNotEmpty);

      final items = await vm.itemsStream.first;
      expect(items.single.item, i);
      expect(items.single.images, isEmpty);
    });

    test('location scope uses watchLocationContainers/watchLocationItems', () async {
      when(dataService.watchLocationContainers('L1'))
          .thenAnswer((_) => Stream.value([]));
      when(dataService.watchLocationItems('L1'))
          .thenAnswer((_) => Stream.value([]));

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.location('L1'),
      );

      expect(await vm.containersStream.first, isEmpty);
      expect(await vm.itemsStream.first, isEmpty);
    });

    test('room scope uses watchRoomContainers/watchRoomItems', () async {
      when(dataService.watchRoomContainers('R1'))
          .thenAnswer((_) => Stream.value([]));
      when(dataService.watchRoomItems('R1'))
          .thenAnswer((_) => Stream.value([]));

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.room('R1'),
      );

      expect(await vm.containersStream.first, isEmpty);
      expect(await vm.itemsStream.first, isEmpty);
    });

    test('container scope uses watchChildContainers/watchContainerItems', () async {
      when(dataService.watchChildContainers('C1'))
          .thenAnswer((_) => Stream.value([]));
      when(dataService.watchContainerItems('C1'))
          .thenAnswer((_) => Stream.value([]));

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.container('C1'),
      );

      expect(await vm.containersStream.first, isEmpty);
      expect(await vm.itemsStream.first, isEmpty);
    });
  });

  group('error handling', () {
    test('containersStream logs errors from dataService and completes gracefully', () async {
      final logger = TestLoggerManager(loggerName: 'ContentsViewModel');
      logger.startCapture();

      when(dataService.watchAllContainers()).thenAnswer((_) {
        return Stream<List<dm.Container>>.fromFuture(
          Future.error(Exception('boom containers')),
        );
      });
      when(dataService.watchAllItems())
          .thenAnswer((_) => Stream.value(<dm.Item>[]));

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.all(),
      );

      // drain should not throw; it will just consume the error
      await vm.containersStream.drain();

      final log = logger.findLogWithMessage(
        'containers stream error',
        level: Level.SEVERE,
      );
      expect(log, isNotNull);
      expect(log!.error, isA<Exception>());

      logger.stopCapture();
    });

    test('itemsStream logs errors from dataService and completes gracefully', () async {
      final logger = TestLoggerManager(loggerName: 'ContentsViewModel');
      logger.startCapture();

      when(dataService.watchAllContainers())
          .thenAnswer((_) => Stream.value(<dm.Container>[]));
      when(dataService.watchAllItems()).thenAnswer((_) {
        return Stream<List<dm.Item>>.fromFuture(
          Future.error(Exception('boom items')),
        );
      });

      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.all(),
      );

      await vm.itemsStream.drain();

      final log = logger.findLogWithMessage(
        'items stream error',
        level: Level.SEVERE,
      );
      expect(log, isNotNull);
      expect(log!.error, isA<Exception>());

      logger.stopCapture();
    });
  });

  group('deleteContainer', () {
    test('does not throw', () async {
      final vm = ContentsViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        scope: const ContentsScope.all(),
      );
      await vm.deleteContainer('C1'); // just logs
    });
  });

  group('ContentsVmFactory', () {
    testWidgets('fromContext builds ViewModel', (tester) async {
      late ContentsViewModel vm;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<IDataService>.value(value: dataService),
            Provider<IImageDataService>.value(value: imageDataService),
          ],
          child: Builder(
            builder: (ctx) {
              vm = ContentsVmFactory.fromContext(
                ctx,
                scope: const ContentsScope.all(),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(vm, isA<ContentsViewModel>());
      expect(vm.title, 'All Contents');
    });
  });
}
