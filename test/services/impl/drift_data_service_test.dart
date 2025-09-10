// test/services/impl/drift_data_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:stuff/data/drift/database.dart';
import 'package:stuff/services/impl/drift_data_service.dart';
import 'package:stuff/services/contracts/data_service_interface.dart';

import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';
import 'package:stuff/domain/models/container_model.dart' as dm;
import 'package:stuff/domain/models/item_model.dart' as dm;

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> seedLocationRoom({String locationId = 'L1', String roomId = 'R1'}) async {
    await svc.addLocation(Location(id: locationId, name: 'Loc'));
    await svc.addRoom(Room(id: roomId, locationId: locationId, name: 'Room'));
  }

  dm.Container makeContainer({
    required String id,
    String roomId = 'R1',
    String? parentId,
    String name = 'Box',
    List<String> guids = const [],
    int? pos,
    String? desc,
  }) {
    return dm.Container(
      id: id,
      roomId: roomId,
      parentContainerId: parentId,
      name: name,
      description: desc,
      imageGuids: guids,
      positionIndex: pos,
    );
  }

  dm.Item makeItem({
    required String id,
    String roomId = 'R1',
    String? containerId,
    required String name,
    String? description,
    Map<String, dynamic> attrs = const {},
    List<String> guids = const [],
    int? pos,
    bool archived = false,
  }) {
    return dm.Item(
      id: id,
      roomId: roomId,
      containerId: containerId,
      name: name,
      description: description,
      attrs: attrs,
      imageGuids: guids,
      positionIndex: pos,
      isArchived: archived,
    );
  }

  Future<Location> insertLocation(String id) async {
    final loc = Location(id: id, name: 'Loc $id');
    await svc.upsertLocation(loc);
    return loc;
  }

  Future<Room> insertRoom(String id, String locId) async {
    final room = Room(id: id, locationId: locId, name: 'Room $id');
    await svc.upsertRoom(room);
    return room;
  }

  Future<dm.Container> insertContainer(String id, String roomId) async {
    final c = dm.Container(id: id, roomId: roomId, name: 'Cont $id');
    await svc.upsertContainer(c);
    return c;
  }

  Future<dm.Item> insertItem(String id, String roomId, {String? containerId}) async {
    final it = dm.Item(id: id, roomId: roomId, containerId: containerId, name: 'Item $id');
    await svc.upsertItem(it);
    return it;
  }

  Matcher hasIds(Iterable<String> expected) =>
      isA<List>().having((l) => l.map((e) => e.id).toList(), 'ids', expected);

  // ---------------------------------------------------------------------------
  // Locations
  // ---------------------------------------------------------------------------
  group('locations', () {
    test('add/get and stream emits', () async {
      final expectStream = expectLater(
        svc.watchLocations(),
        emitsInOrder([
          hasIds(['L1']),
          hasIds(['L1', 'L2']),
        ]),
      );

      await svc.addLocation(Location(id: 'L1', name: 'Home'));
      await svc.addLocation(Location(id: 'L2', name: 'Office'));

      expect(await svc.getAllLocations(), hasIds(['L1', 'L2']));

      await expectStream;
    });

    test('deleteLocation cascades rooms via FK', () async {
      await svc.addLocation(Location(id: 'L1', name: 'Home'));
      await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));
      await svc.addRoom(Room(id: 'R2', locationId: 'L1', name: 'Lounge'));

      await svc.deleteLocation('L1');

      expect(await svc.getLocationById('L1'), isNull);
      expect(await svc.getRoomsForLocation('L1'), isEmpty);
      expect(await svc.getRoomById('R1'), isNull);
      expect(await svc.getRoomById('R2'), isNull);
    });

    test('clearAllData wipes tables and streams emit empty', () async {
      await seedLocationRoom();

      final expectLocs = expectLater(svc.watchLocations(), emitsThrough(hasIds([])));
      final expectRooms = expectLater(svc.watchRooms('L1'), emitsThrough(hasIds([])));

      await svc.clearAllData();

      expect(await svc.getAllLocations(), isEmpty);
      expect(await svc.getRoomsForLocation('L1'), isEmpty);

      await expectLocs;
      await expectRooms;
    });
  });

  // ---------------------------------------------------------------------------
  // Rooms
  // ---------------------------------------------------------------------------
  group('rooms', () {
    test('watch per-location and basic CRUD', () async {
      await svc.addLocation(Location(id: 'L1', name: 'Home'));

      final expectRooms = expectLater(
        svc.watchRooms('L1'),
        emitsInOrder([
          hasIds(['R1']),
        ]),
      );

      await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));
      expect(await svc.getRoomById('R1'), isNotNull);
      expect(await svc.getRoomsForLocation('L1'), hasIds(['R1']));

      await expectRooms;
    });

    test('updateRoom can move between locations and streams update both sides', () async {
      await svc.addLocation(Location(id: 'L1', name: 'Home'));
      await svc.addLocation(Location(id: 'L2', name: 'Office'));
      await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Spare'));

      final expectL1 = expectLater(
        svc.watchRooms('L1'),
        emitsInOrder([
          hasIds(['R1']),
          hasIds([]),
        ]),
      );
      final expectL2 = expectLater(
        svc.watchRooms('L2'),
        emitsInOrder([
          hasIds([]),
          hasIds(['R1']),
        ]),
      );

      await svc.updateRoom(Room(id: 'R1', locationId: 'L2', name: 'Spare'));

      expect(await svc.getRoomsForLocation('L1'), isEmpty);
      expect(await svc.getRoomsForLocation('L2'), hasIds(['R1']));

      await expectL1;
      await expectL2;
    });

    test('deleteRoom cascades containers and items', () async {
      await seedLocationRoom();
      await svc.addContainer(makeContainer(id: 'C1'));
      await svc.addItem(makeItem(id: 'I1', name: 'RoomItem'));
      await svc.addItem(makeItem(id: 'I2', containerId: 'C1', name: 'InContainer'));

      await svc.deleteRoom('R1');

      expect(await svc.getRoomContainers('R1'), isEmpty);
      expect(await svc.getItemsInRoom('R1'), isEmpty);
      expect(await svc.getItemById('I1'), isNull);
      expect(await svc.getItemById('I2'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Containers
  // ---------------------------------------------------------------------------
  group('containers', () {
    test('top-level stream and CRUD', () async {
      await seedLocationRoom();

      final expectStream = expectLater(svc.watchRoomContainers('R1'), emitsThrough(hasIds(['C1'])));

      await svc.addContainer(makeContainer(id: 'C1', name: 'Crate'));
      expect(await svc.getRoomContainers('R1'), hasIds(['C1']));

      await svc.upsertContainer(makeContainer(id: 'C1', name: 'Renamed'));
      expect((await svc.getContainerById('C1'))?.name, 'Renamed');

      await expectStream;
    });

    test('child containers stream + cascade delete', () async {
      await seedLocationRoom();
      await svc.addContainer(makeContainer(id: 'P', name: 'Parent'));

      final expectChildren = expectLater(
        svc.watchChildContainers('P'),
        emitsThrough(hasIds(['C1', 'C2'])),
      );

      await svc.addContainer(makeContainer(id: 'C1', parentId: 'P'));
      await svc.addContainer(makeContainer(id: 'C2', parentId: 'P'));
      expect(await svc.getChildContainers('P'), hasIds(['C1', 'C2']));

      await svc.deleteContainer('P');
      expect(await svc.getChildContainers('P'), isEmpty);

      await expectChildren;
    });

    test('deleteContainer cascades to descendant containers and their items', () async {
      await seedLocationRoom();
      final c1 = await svc.addContainer(makeContainer(id: 'C1'));
      final c1a = await svc.addContainer(makeContainer(id: 'C1a', parentId: c1.id));
      final c1a1 = await svc.addContainer(makeContainer(id: 'C1a1', parentId: c1a.id));
      final c1b = await svc.addContainer(makeContainer(id: 'C1b', parentId: c1.id));
      final c2 = await svc.addContainer(makeContainer(id: 'C2')); // survivor

      await svc.addItem(makeItem(id: 'IR', name: 'RoomItem'));
      final iC1 = await svc.addItem(makeItem(id: 'IC1', containerId: c1.id, name: 'InC1'));
      final iC1a = await svc.addItem(makeItem(id: 'IC1a', containerId: c1a.id, name: 'InC1a'));
      await svc.addItem(makeItem(id: 'IC1a1', containerId: c1a1.id, name: 'InC1a1'));
      await svc.addItem(makeItem(id: 'IC1b', containerId: c1b.id, name: 'InC1b'));
      final iC2 = await svc.addItem(makeItem(id: 'IC2', containerId: c2.id, name: 'InC2'));

      await svc.deleteContainer(c1.id);

      expect(await svc.getContainerById(c1.id), isNull);
      expect(await svc.getItemById(iC1.id), isNull);
      expect(await svc.getItemById(iC1a.id), isNull);

      expect(await svc.getContainerById(c2.id), isNotNull);
      expect(await svc.getItemById(iC2.id), isNotNull);
      expect(await svc.getItemById('IR'), isNotNull);
    });

    test('watchLocationContainers/getLocationContainers return seeded containers', () async {
      final loc = await insertLocation('L1');
      final room = await insertRoom('R1', loc.id);
      final c = await insertContainer('C1', room.id);

      expect(await svc.watchLocationContainers(loc.id).first, hasIds([c.id]));
      expect(await svc.getLocationContainers(loc.id), hasIds([c.id]));
    });

    test('watchAllContainers/getAllContainers return seeded containers', () async {
      final loc = await insertLocation('L1');
      final room = await insertRoom('R1', loc.id);
      final c = await insertContainer('C1', room.id);

      expect(await svc.watchAllContainers().first, hasIds([c.id]));
      expect(await svc.getAllContainers(), hasIds([c.id]));
    });
  });

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------
  group('items', () {
    test('watch items in room and in container', () async {
      await seedLocationRoom();
      await svc.addContainer(makeContainer(id: 'C1'));

      final expectRoom = expectLater(svc.watchRoomItems('R1'), emitsThrough(hasIds(['I1'])));
      final expectCont = expectLater(svc.watchContainerItems('C1'), emitsThrough(hasIds(['I2'])));

      await svc.addItem(makeItem(id: 'I1', name: 'Chair'));
      await svc.addItem(makeItem(id: 'I2', containerId: 'C1', name: 'Lamp'));

      expect(await svc.getItemsInRoom('R1'), hasIds(['I1']));
      expect(await svc.getItemsInContainer('C1'), hasIds(['I2']));

      await expectRoom;
      await expectCont;
    });

    test('move between container and room via update', () async {
      await seedLocationRoom();
      await svc.addContainer(makeContainer(id: 'C1'));
      await svc.addItem(makeItem(id: 'I1', containerId: 'C1', name: 'Thing'));

      await svc.updateItem(makeItem(id: 'I1', containerId: null, name: 'Thing'));
      expect(await svc.getItemsInRoom('R1'), hasIds(['I1']));

      await svc.updateItem(makeItem(id: 'I1', containerId: 'C1', name: 'Thing'));
      expect(await svc.getItemsInContainer('C1'), hasIds(['I1']));
    });

    test('archive/unarchive hides from streams but keeps record', () async {
      await seedLocationRoom();
      await svc.addItem(makeItem(id: 'I1', name: 'Archived Candidate'));

      await svc.setItemArchived('I1', true);
      expect(await svc.getItemsInRoom('R1'), isEmpty);
      expect((await svc.getItemById('I1'))?.isArchived, isTrue);

      await svc.setItemArchived('I1', false);
      expect(await svc.getItemsInRoom('R1'), hasIds(['I1']));
    });

    test('upsert + description + attrs round-trip', () async {
      await seedLocationRoom();
      final item = makeItem(
        id: 'I1',
        name: 'Desk',
        description: 'Oak desk',
        attrs: {'color': 'brown'},
        guids: ['g1'],
      );

      await svc.upsertItem(item);
      var loaded = await svc.getItemById('I1');
      expect(loaded?.description, 'Oak desk');
      expect(loaded?.attrs['color'], 'brown');
      expect(loaded?.imageGuids, ['g1']);

      await svc.upsertItem(item.copyWith(description: 'Refinished', attrs: {'color': 'black'}));
      loaded = await svc.getItemById('I1');
      expect(loaded?.description, 'Refinished');
      expect(loaded?.attrs['color'], 'black');
    });

    test('watchLocationItems/watchAllItems return seeded items', () async {
      final loc = await insertLocation('L1');
      final room = await insertRoom('R1', loc.id);
      final it = await insertItem('I1', room.id);

      expect(await svc.watchLocationItems(loc.id).first, hasIds([it.id]));
      expect(await svc.watchAllItems().first, hasIds([it.id]));
    });

    test('deleteItem removes the item', () async {
      final loc = await insertLocation('L1');
      final room = await insertRoom('R1', loc.id);
      final it = await insertItem('I1', room.id);

      expect(await svc.watchAllItems().first, hasIds([it.id]));
      await svc.deleteItem(it.id);
      expect(await svc.watchAllItems().first, hasIds([]));
    });
  });

  // ---------------------------------------------------------------------------
  // Service lifecycle
  // ---------------------------------------------------------------------------
  group('service lifecycle', () {
    test('dispose closes database and prevents further use', () async {
      await svc.dispose();

      // Further calls should throw StateError due to _ensureReady()
      expect(() => svc.watchLocations(), throwsA(isA<StateError>()));
      expect(() => svc.getAllLocations(), throwsA(isA<StateError>()));
    });

    test('dispose is idempotent', () async {
      await svc.dispose();
      // Calling dispose again should not throw
      await svc.dispose();
    });
  });
}
