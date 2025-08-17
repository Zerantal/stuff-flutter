import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:stuff/data/drift/database.dart';
import 'package:stuff/services/impl/drift_data_service.dart';
import 'package:stuff/services/contracts/data_service_interface.dart';

import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';

void main() {
  late AppDatabase db;
  late IDataService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    svc = DriftDataService(db);
  });

  tearDown(() async {
    await svc.dispose();
  });

  test('locations: add/get and stream emits', () async {
    final expectStream = expectLater(
      svc.getLocationsStream(),
      emitsInOrder([
        isA<List<Location>>().having((l) => l.map((e) => e.id).toList(), 'after L1', ['L1']),
        isA<List<Location>>().having((l) => l.map((e) => e.id).toList(), 'after L2', ['L1', 'L2']),
      ]),
    );

    await svc.addLocation(Location(id: 'L1', name: 'Home'));
    await svc.addLocation(Location(id: 'L2', name: 'Office'));

    final all = await svc.getAllLocations();
    expect(all.map((e) => e.id), ['L1', 'L2']);

    await expectStream;
  });

  test('rooms: watch per-location and basic CRUD', () async {
    await svc.addLocation(Location(id: 'L1', name: 'Home'));

    // Watch for L1; expect initial empty, then 1 room
    final expectRoomsL1 = expectLater(
      svc.getRoomsStream('L1'),
      emitsInOrder([isA<List<Room>>().having((l) => l.single.id, 'after add', 'R1')]),
    );

    await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));
    final r = await svc.getRoomById('R1');
    expect(r?.name, 'Kitchen');
    expect(r?.locationId, 'L1');

    final list = await svc.getRoomsForLocation('L1');
    expect(list.map((e) => e.id), ['R1']);

    await expectRoomsL1;
  });

  test('deleteLocation cascades rooms via FK', () async {
    await svc.addLocation(Location(id: 'L1', name: 'Home'));
    await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));
    await svc.addRoom(Room(id: 'R2', locationId: 'L1', name: 'Lounge'));

    // Sanity
    expect((await svc.getRoomsForLocation('L1')).length, 2);

    await svc.deleteLocation('L1');

    // Location gone, rooms gone
    expect(await svc.getLocationById('L1'), isNull);
    expect(await svc.getRoomsForLocation('L1'), isEmpty);
    expect(await svc.getRoomById('R1'), isNull);
    expect(await svc.getRoomById('R2'), isNull);
  });

  test('updateRoom can move between locations and streams update both sides', () async {
    await svc.addLocation(Location(id: 'L1', name: 'Home'));
    await svc.addLocation(Location(id: 'L2', name: 'Office'));
    await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Spare'));

    // Watch both locations
    final expectL1 = expectLater(
      svc.getRoomsStream('L1'),
      emitsInOrder([
        isA<List<Room>>().having((l) => l.length, 'initial after add', 1),
        isA<List<Room>>().having((l) => l.length, 'after move away', 0),
      ]),
    );

    final expectL2 = expectLater(
      svc.getRoomsStream('L2'),
      emitsInOrder([
        isA<List<Room>>().having((l) => l.length, 'initial empty', 0),
        isA<List<Room>>().having((l) => l.single.id, 'after move in', 'R1'),
      ]),
    );

    // Move room R1 from L1 -> L2
    final moved = Room(id: 'R1', locationId: 'L2', name: 'Spare');
    await svc.updateRoom(moved);

    // Assert lookup reflects new parent
    final l1Rooms = await svc.getRoomsForLocation('L1');
    final l2Rooms = await svc.getRoomsForLocation('L2');
    expect(l1Rooms, isEmpty);
    expect(l2Rooms.map((e) => e.id), ['R1']);

    await expectL1;
    await expectL2;
  });

  test('clearAllData wipes tables and streams emit empty', () async {
    await svc.addLocation(Location(id: 'L1', name: 'Home'));
    await svc.addLocation(Location(id: 'L2', name: 'Office'));
    await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));

    // Expect locations stream to eventually emit empty after clear
    final expectLocs = expectLater(
      svc.getLocationsStream(),
      emitsThrough(isA<List<Location>>().having((l) => l.length, 'after clear', 0)),
    );
    // Rooms stream for L1 should also emit empty after clear
    final expectRooms = expectLater(
      svc.getRoomsStream('L1'),
      emitsThrough(isA<List<Room>>().having((l) => l.length, 'after clear', 0)),
    );

    await svc.clearAllData();

    expect(await svc.getAllLocations(), isEmpty);
    expect(await svc.getRoomsForLocation('L1'), isEmpty);

    await expectLocs;
    await expectRooms;
  });
}
