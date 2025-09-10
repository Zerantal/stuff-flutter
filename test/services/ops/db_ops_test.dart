// test/services/ops/db_ops_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/services/ops/db_ops.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';
import 'package:stuff/domain/models/container_model.dart';
import 'package:stuff/domain/models/item_model.dart';

import '../../utils/mocks.mocks.dart';

void main() {
  late MockIDataService data;
  late MockIImageDataService images;
  late DbOps ops;

  setUp(() {
    data = MockIDataService();
    images = MockIImageDataService();
    ops = DbOps(data, images);

    when(data.runInTransaction(any)).thenAnswer((invocation) {
      final action = invocation.positionalArguments[0] as Future Function();
      return action();
    });
  });

  group('DbOps.deleteLocation', () {
    test(
      'deletes location and all associated images (location + rooms + containers + items)',
      () async {
        const locId = 'L1';
        final loc = Location(
          id: locId,
          name: 'Loc',
          address: '123 St',
          description: 'desc',
          imageGuids: const ['L1_Img1', 'L1_Img2'],
        );
        final rooms = <Room>[
          Room(
            id: 'R1',
            name: 'Room 1',
            locationId: locId,
            description: null,
            imageGuids: const ['R1IMG'],
          ),
          Room(
            id: 'R2',
            name: 'Room 2',
            locationId: locId,
            description: 'x',
            imageGuids: const ['R2A', 'R2B'],
          ),
        ];
        final containers = <Container>[
          Container(id: 'C1', roomId: 'R1', name: 'Box', imageGuids: const ['CIMG']),
        ];
        final items = <Item>[
          Item(id: 'I1', roomId: 'R1', name: 'Chair', imageGuids: const ['IIMG']),
        ];

        when(data.getLocationById(locId)).thenAnswer((_) async => loc);
        when(data.getRoomsForLocation(locId)).thenAnswer((_) async => rooms);
        when(data.getRoomContainers('R1')).thenAnswer((_) async => containers);
        when(data.getRoomContainers('R2')).thenAnswer((_) async => const <Container>[]);
        when(data.getChildContainers(any)).thenAnswer((_) async => const <Container>[]);
        when(data.getItemsInRoom('R1')).thenAnswer((_) async => items);
        when(data.getItemsInRoom('R2')).thenAnswer((_) async => const <Item>[]);
        when(data.deleteLocation(locId)).thenAnswer((_) async {});

        await ops.deleteLocation(locId);

        verify(data.runInTransaction<void>(any)).called(1);

        verify(data.getLocationById(locId)).called(1);
        verify(data.getRoomsForLocation(locId)).called(1);
        verify(data.getRoomContainers('R1')).called(1);
        verify(data.getRoomContainers('R2')).called(1);
        verify(data.getChildContainers('C1')).called(1);
        verify(data.getItemsInRoom('R1')).called(1);
        verify(data.getItemsInRoom('R2')).called(1);
        verify(data.deleteLocation(locId)).called(1);

        final expected = ['L1_Img1', 'L1_Img2', 'R1IMG', 'R2A', 'R2B', 'CIMG', 'IIMG'];
        for (final g in expected) {
          verify(images.deleteImage(g)).called(1);
        }
        verifyNoMoreInteractions(images);
      },
    );

    test('no-op if location does not exist', () async {
      const locId = 'L404';
      when(data.getLocationById(locId)).thenAnswer((_) async => null);

      await ops.deleteLocation(locId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getLocationById(locId)).called(1);
      verifyNever(data.getRoomsForLocation(any));
      verifyNever(data.deleteLocation(any));
      verifyNever(images.deleteImage(any));
    });

    test('rethrows on deleteLocation error and does NOT delete images', () async {
      const locId = 'L1';
      final loc = Location(
        id: locId,
        name: 'Loc',
        address: '',
        description: null,
        imageGuids: const ['A'],
      );
      when(data.getLocationById(locId)).thenAnswer((_) async => loc);
      when(data.getRoomsForLocation(locId)).thenAnswer((_) async => const <Room>[]);
      when(data.getRoomContainers(any)).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInRoom(any)).thenAnswer((_) async => const <Item>[]);
      when(data.deleteLocation(locId)).thenThrow(Exception('boom'));

      await expectLater(ops.deleteLocation(locId), throwsA(isA<Exception>()));

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getLocationById(locId)).called(1);
      verify(data.getRoomsForLocation(locId)).called(1);
      verify(data.deleteLocation(locId)).called(1);

      verifyNever(images.deleteImage(any));
    });
  });

  group('DbOps.deleteRoom', () {
    test('deletes room, its images, and container images/items', () async {
      const roomId = 'R1';
      final room = Room(
        id: roomId,
        name: 'Room',
        locationId: 'L1',
        description: null,
        imageGuids: const ['IMG1', 'IMG2'],
      );

      // Container in this room
      final container = Container(
        id: 'C1',
        roomId: roomId,
        name: 'Box',
        description: null,
        parentContainerId: null,
        imageGuids: const ['CIMG'],
      );

      // Item inside the container
      final item = Item(
        id: 'I1',
        roomId: roomId,
        containerId: container.id,
        name: 'Lamp',
        description: null,
        imageGuids: const ['IIMG'],
      );

      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.getRoomContainers(roomId)).thenAnswer((_) async => [container]);
      when(data.getChildContainers(container.id)).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInContainer(container.id)).thenAnswer((_) async => [item]);
      when(data.getItemsInRoom(roomId)).thenAnswer((_) async => const <Item>[]);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getRoomById(roomId)).called(1);
      verify(data.getRoomContainers(roomId)).called(1);
      verify(data.getChildContainers(container.id)).called(1);
      verify(data.getItemsInContainer(container.id)).called(1);
      verify(data.getItemsInRoom(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);

      // Room images
      verify(images.deleteImage('IMG1')).called(1);
      verify(images.deleteImage('IMG2')).called(1);

      // Container + item images
      verify(images.deleteImage('CIMG')).called(1);
      verify(images.deleteImage('IIMG')).called(1);
    });

    test('room with no images still deleted', () async {
      const roomId = 'R2';
      final room = Room(
        id: roomId,
        name: 'Empty',
        locationId: 'L1',
        description: null,
        imageGuids: const [],
      );
      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.getRoomContainers(roomId)).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInRoom(roomId)).thenAnswer((_) async => const <Item>[]);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);
      verifyNever(images.deleteImage(any));
    });

    test('deletes room even if not found', () async {
      const roomId = 'R404';
      when(data.getRoomById(roomId)).thenAnswer((_) async => null);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);
      verifyNever(images.deleteImage(any));
    });

    test('rethrows on deleteRoom error and does NOT delete images', () async {
      const roomId = 'RERR';
      final room = Room(
        id: roomId,
        name: 'Err',
        locationId: 'L1',
        description: null,
        imageGuids: const ['X'],
      );
      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.getRoomContainers(roomId)).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInRoom(roomId)).thenAnswer((_) async => const <Item>[]);
      when(data.deleteRoom(roomId)).thenThrow(StateError('nope'));

      await expectLater(ops.deleteRoom(roomId), throwsA(isA<StateError>()));

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);

      verifyNever(images.deleteImage(any));
    });
  });

  group('DbOps.deleteContainer', () {
    test('deletes container + child containers + items + images', () async {
      const cId = 'C1';
      final container = Container(id: cId, roomId: 'R1', name: 'Cont', imageGuids: const ['CIMG']);
      final child = Container(
        id: 'C2',
        roomId: 'R1',
        parentContainerId: cId,
        name: 'Child',
        imageGuids: const ['C2IMG'],
      );
      final item = Item(
        id: 'I1',
        roomId: 'R1',
        containerId: cId,
        name: 'Item',
        imageGuids: const ['IIMG'],
      );

      when(data.getContainerById(cId)).thenAnswer((_) async => container);
      when(data.getChildContainers(cId)).thenAnswer((_) async => [child]);
      when(data.getChildContainers('C2')).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInContainer(cId)).thenAnswer((_) async => [item]);
      when(data.getItemsInContainer('C2')).thenAnswer((_) async => const <Item>[]);
      when(data.deleteContainer(any)).thenAnswer((_) async {});

      await ops.deleteContainer(cId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getContainerById(cId)).called(1);
      verify(data.getChildContainers(cId)).called(1);
      verify(data.getItemsInContainer(cId)).called(1);
      verify(data.deleteContainer(cId)).called(1);

      verify(images.deleteImage('CIMG')).called(1);
      verify(images.deleteImage('C2IMG')).called(1);
      verify(images.deleteImage('IIMG')).called(1);
    });

    test('no-op if container does not exist', () async {
      const cId = 'C404';
      when(data.getContainerById(cId)).thenAnswer((_) async => null);

      await ops.deleteContainer(cId);

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getContainerById(cId)).called(1);
      verifyNever(data.deleteContainer(any));
      verifyNever(images.deleteImage(any));
    });

    test('rethrows on deleteContainer error and does NOT delete images', () async {
      const cId = 'CERR';
      final container = Container(id: cId, roomId: 'R1', name: 'Err', imageGuids: const ['X']);
      when(data.getContainerById(cId)).thenAnswer((_) async => container);
      when(data.getChildContainers(cId)).thenAnswer((_) async => const <Container>[]);
      when(data.getItemsInContainer(cId)).thenAnswer((_) async => const <Item>[]);
      when(data.deleteContainer(cId)).thenThrow(StateError('boom'));

      await expectLater(ops.deleteContainer(cId), throwsA(isA<StateError>()));

      verify(data.runInTransaction<void>(any)).called(1);
      verify(data.getContainerById(cId)).called(1);
      verify(data.deleteContainer(cId)).called(1);

      verifyNever(images.deleteImage(any));
    });
  });

  group('DbOps.deleteItem', () {
    test('deletes item and its images when found', () async {
      const itemId = 'I1';
      final item = Item(
        id: itemId,
        roomId: 'R1',
        name: 'Chair',
        description: null,
        imageGuids: const ['IMG1', 'IMG2'],
      );

      when(data.getItemById(itemId)).thenAnswer((_) async => item);
      when(data.deleteItem(itemId)).thenAnswer((_) async {});
      when(data.runInTransaction<void>(any)).thenAnswer((inv) => inv.positionalArguments[0]());

      await ops.deleteItem(itemId);

      verifyInOrder([
        data.runInTransaction<void>(any),
        data.getItemById(itemId),
        data.deleteItem(itemId),
      ]);

      verify(images.deleteImage(any)).called(2);
    });

    test('no-op if item does not exist', () async {
      const itemId = 'I404';
      when(data.getItemById(itemId)).thenAnswer((_) async => null);
      when(data.runInTransaction<void>(any)).thenAnswer((inv) => inv.positionalArguments[0]());

      await ops.deleteItem(itemId);

      verify(data.getItemById(itemId)).called(1);
      verifyNever(data.deleteItem(any));
      verifyNever(images.deleteImage(any));
    });

    test('rethrows if deleteItem fails and does NOT delete images', () async {
      const itemId = 'IERR';
      final item = Item(
        id: itemId,
        roomId: 'R1',
        name: 'Broken',
        description: null,
        imageGuids: const ['X'],
      );

      when(data.getItemById(itemId)).thenAnswer((_) async => item);
      when(data.deleteItem(itemId)).thenThrow(Exception('boom'));
      when(data.runInTransaction<void>(any)).thenAnswer((inv) => inv.positionalArguments[0]());

      await expectLater(ops.deleteItem(itemId), throwsA(isA<Exception>()));

      verify(data.getItemById(itemId)).called(1);
      verify(data.deleteItem(itemId)).called(1);
      verifyNever(images.deleteImage(any));
    });
  });
}
