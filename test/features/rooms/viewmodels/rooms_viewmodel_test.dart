import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/room/viewmodels/rooms_view_model.dart';
import 'package:stuff/domain/models/room_model.dart';

import '../../../utils/mocks.dart';

void main() {
  group('RoomsViewModel', () {
    late MockIDataService data;
    late MockIImageDataService images;

    setUp(() {
      data = MockIDataService();
      images = MockIImageDataService();
    });

    test('maps rooms stream into RoomListItem', () async {
      // Arrange a controllable stream
      final controller = StreamController<List<Room>>();
      when(data.getRoomsStream('L1')).thenAnswer((_) => controller.stream);

      final vm = RoomsViewModel(
        data: data,
        images: images,
        locationId: 'L1',
      );

      // Act / Assert: first emission
      final futureFirst = vm.rooms.first;
      final roomsBatch = [
        Room(id: 'R1', locationId: 'L1', name: 'Kitchen', imageGuids: const []),
        Room(id: 'R2', locationId: 'L1', name: 'Garage', imageGuids: const []),
      ];
      controller.add(roomsBatch);

      final items = await futureFirst;
      expect(items.length, 2);
      expect(items[0].room.id, 'R1');
      expect(items[0].images, isEmpty);
      expect(items[1].room.name, 'Garage');

      await controller.close();
    });

    test('deleteRoom completes (delegates to DbOps behind the scenes)', () async {
      // We don’t stub DbOps directly; we just ensure the call completes.
      // If DbOps internally calls IDataService methods, we keep them permissive.
      when(data.getRoomsStream(any)).thenAnswer((_) => const Stream<List<Room>>.empty());
      when(data.deleteRoom('R-Z')).thenAnswer((_) async => Future.value());

      final vm = RoomsViewModel(
        data: data,
        images: images,
        locationId: 'L1',
      );

      await vm.deleteRoom('R-Z'); // Should not throw
      verify(data.deleteRoom('R-Z')).called(1);
    });
  });
}
