import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/services/ops/db_ops.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';

import '../../utils/mocks.mocks.dart';

void main() {
  late MockIDataService data;
  late MockIImageDataService images;
  late DbOps ops;

  setUp(() {
    data = MockIDataService();
    images = MockIImageDataService();
    ops = DbOps(data, images);
  });

  group('DbOps.deleteLocation', () {
    test('deletes location and all associated images (from location and its rooms)', () async {
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

      when(data.getLocationById(locId)).thenAnswer((_) async => loc);
      when(data.getRoomsForLocation(locId)).thenAnswer((_) async => rooms);
      when(data.deleteLocation(locId)).thenAnswer((_) async {});

      await ops.deleteLocation(locId);

      verifyInOrder([
        data.getLocationById(locId),
        data.getRoomsForLocation(locId),
        data.deleteLocation(locId),
      ]);

      final expected = ['L1_Img1', 'L1_Img2', 'R1IMG', 'R2A', 'R2B'];
      for (final g in expected) {
        verify(images.deleteImage(g)).called(1);
      }
      verifyNoMoreInteractions(images);
    });

    test('no-op if location does not exist (no deletes, no image calls)', () async {
      const locId = 'L404';
      when(data.getLocationById(locId)).thenAnswer((_) async => null);

      await ops.deleteLocation(locId);

      verify(data.getLocationById(locId)).called(1);
      verifyNever(data.getRoomsForLocation(any));
      verifyNever(data.deleteLocation(any));
      verifyNever(images.deleteImage(any));
    });

    test('rethrows on dataService.deleteLocation error and does NOT delete images', () async {
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
      when(data.deleteLocation(locId)).thenThrow(Exception('boom'));

      await expectLater(ops.deleteLocation(locId), throwsA(isA<Exception>()));

      verifyInOrder([
        data.getLocationById(locId),
        data.getRoomsForLocation(locId),
        data.deleteLocation(locId),
      ]);

      verifyNever(images.deleteImage(any));
    });
  });

  group('DbOps.deleteRoom', () {
    test('deletes room and its images when room exists with images', () async {
      const roomId = 'R1';
      final room = Room(
        id: roomId,
        name: 'Room',
        locationId: 'L1',
        description: null,
        imageGuids: const ['IMG1', 'IMG2'],
      );

      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);

      verify(images.deleteImage('IMG1')).called(1);
      verify(images.deleteImage('IMG2')).called(1);
      verifyNoMoreInteractions(images);
    });

    test('deletes room but not images when room has no images', () async {
      const roomId = 'R2';
      final room = Room(
        id: roomId,
        name: 'Empty',
        locationId: 'L1',
        description: null,
        imageGuids: const [],
      );

      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);
      verifyNever(images.deleteImage(any));
    });

    test('deletes room even if not found (no images deleted)', () async {
      const roomId = 'R404';
      when(data.getRoomById(roomId)).thenAnswer((_) async => null);
      when(data.deleteRoom(roomId)).thenAnswer((_) async {});

      await ops.deleteRoom(roomId);

      verify(data.getRoomById(roomId)).called(1);
      verify(data.deleteRoom(roomId)).called(1);
      verifyNever(images.deleteImage(any));
    });

    test('rethrows on dataService.deleteRoom error and does NOT delete images', () async {
      const roomId = 'RERR';
      final room = Room(
        id: roomId,
        name: 'Err',
        locationId: 'L1',
        description: null,
        imageGuids: const ['X'],
      );

      when(data.getRoomById(roomId)).thenAnswer((_) async => room);
      when(data.deleteRoom(roomId)).thenThrow(StateError('nope'));

      await expectLater(ops.deleteRoom(roomId), throwsA(isA<StateError>()));

      verifyInOrder([data.getRoomById(roomId), data.deleteRoom(roomId)]);

      verifyNever(images.deleteImage(any));
    });
  });
}
