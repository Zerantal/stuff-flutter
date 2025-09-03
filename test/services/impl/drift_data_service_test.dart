// test/services/impl/drift_data_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:stuff/data/drift/database.dart';
import 'package:stuff/services/impl/drift_data_service.dart';
import 'package:stuff/services/contracts/data_service_interface.dart';

import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';
import 'package:stuff/domain/models/container_model.dart';
import 'package:stuff/domain/models/item_model.dart';

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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> seedLocationRoom({String locationId = 'L1', String roomId = 'R1'}) async {
    await svc.addLocation(Location(id: locationId, name: 'Loc'));
    await svc.addRoom(Room(id: roomId, locationId: locationId, name: 'Room'));
  }

  Container container({
    required String id,
    String roomId = 'R1',
    String? parentId,
    String name = 'Box',
    List<String> guids = const [],
    int? pos,
    String? desc,
  }) {
    return Container(
      id: id,
      roomId: roomId,
      parentContainerId: parentId,
      name: name,
      description: desc,
      imageGuids: guids,
      positionIndex: pos,
    );
  }

  Item item0({
    required String id,
    String roomId = 'R1',
    String? containerId,
    String? name,
    String? description,
    Map<String, dynamic> attrs = const {},
    List<String> guids = const [],
    int? pos,
    bool archived = false,
  }) {
    return Item(
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

  // ---------------------------------------------------------------------------
  // Containers
  // ---------------------------------------------------------------------------

  test('containers: top-level stream and CRUD', () async {
    await seedLocationRoom();

    final streamExpectation = expectLater(
      svc.watchTopLevelContainers('R1'),
      emitsThrough(
        isA<List<Container>>().having((l) => l.map((c) => c.id).toList(), 'ids', ['C1', 'C2']),
      ),
    );

    await svc.addContainer(container(id: 'C1', name: 'Crate'));
    await svc.addContainer(container(id: 'C2', name: 'Bin'));

    final list = await svc.getTopLevelContainers('R1');
    expect(list.map((c) => c.id).toList(), ['C1', 'C2']);

    // update via upsert
    await svc.upsertContainer(container(id: 'C1', name: 'Crate (renamed)'));
    final c1 = await svc.getContainerById('C1');
    expect(c1?.name, 'Crate (renamed)');

    await streamExpectation;
  });

  test('containers: child containers stream + cascade delete', () async {
    await seedLocationRoom();

    // Parent + 2 children
    await svc.addContainer(container(id: 'P', name: 'Parent'));
    final expectChildren = expectLater(
      svc.watchChildContainers('P'),
      emitsThrough(isA<List<Container>>().having((l) => l.length, 'children length', 2)),
    );

    await svc.addContainer(container(id: 'C1', parentId: 'P', name: 'Child1'));
    await svc.addContainer(container(id: 'C2', parentId: 'P', name: 'Child2'));

    var kids = await svc.getChildContainers('P');
    expect(kids.map((e) => e.id).toList(), ['C1', 'C2']);

    // Delete parent -> children should cascade (gone)
    await svc.deleteContainer('P');
    kids = await svc.getChildContainers('P');
    expect(kids, isEmpty);
    expect(await svc.getContainerById('C1'), isNull);
    expect(await svc.getContainerById('C2'), isNull);

    await expectChildren;
  });

  test('deleteRoom cascades containers', () async {
    await seedLocationRoom();
    await svc.addContainer(container(id: 'C1'));
    await svc.addContainer(container(id: 'C2'));

    expect((await svc.getTopLevelContainers('R1')).length, 2);

    await svc.deleteRoom('R1');

    expect(await svc.getTopLevelContainers('R1'), isEmpty);
    expect(await svc.getContainerById('C1'), isNull);
    expect(await svc.getContainerById('C2'), isNull);
  });

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  test('items: watch items in room and in container', () async {
    await seedLocationRoom();
    await svc.addContainer(container(id: 'C1', name: 'Box'));

    final expectRoomItems = expectLater(
      svc.watchItemsInRoom('R1'),
      emitsThrough(
        isA<List<Item>>().having((l) => l.map((i) => i.id).toList(), 'room items ids', ['I1']),
      ),
    );
    final expectContainerItems = expectLater(
      svc.watchItemsInContainer('C1'),
      emitsThrough(
        isA<List<Item>>().having((l) => l.map((i) => i.id).toList(), 'container items ids', ['I2']),
      ),
    );

    await svc.addItem(item0(id: 'I1', name: 'Chair')); // room level
    await svc.addItem(item0(id: 'I2', containerId: 'C1', name: 'Lamp')); // in container

    final inRoom = await svc.getItemsInRoom('R1');
    expect(inRoom.map((e) => e.id).toList(), contains('I1'));

    final inC1 = await svc.getItemsInContainer('C1');
    expect(inC1.map((e) => e.id).toList(), ['I2']);

    await expectRoomItems;
    await expectContainerItems;
  });

  test('items: move between container and room via update', () async {
    await seedLocationRoom();
    await svc.addContainer(container(id: 'C1'));

    await svc.addItem(item0(id: 'I1', containerId: 'C1', name: 'Thing'));

    // Move out to room (null container)
    final movedOut = item0(id: 'I1', containerId: null, name: 'Thing');
    await svc.updateItem(movedOut);

    final roomItems = await svc.getItemsInRoom('R1');
    expect(roomItems.map((e) => e.id), contains('I1'));
    expect(await svc.getItemsInContainer('C1'), isEmpty);

    // Move back into container
    final movedIn = item0(id: 'I1', containerId: 'C1', name: 'Thing');
    await svc.updateItem(movedIn);

    expect((await svc.getItemsInContainer('C1')).map((e) => e.id), ['I1']);
  });

  test('items: archive/unarchive hides from streams but keeps record', () async {
    await seedLocationRoom();
    await svc.addItem(item0(id: 'I1', name: 'Archived Candidate'));

    // Archive
    await svc.setItemArchived('I1', true);

    // Not visible in room stream/query
    expect(await svc.getItemsInRoom('R1'), isEmpty);

    // Still retrievable directly
    final i = await svc.getItemById('I1');
    expect(i, isNotNull);
    expect(i!.isArchived, isTrue);

    // Unarchive
    await svc.setItemArchived('I1', false);
    expect((await svc.getItemsInRoom('R1')).map((e) => e.id), ['I1']);
  });

  test('items: upsert + description + attrs round-trip', () async {
    await seedLocationRoom();

    final item = item0(
      id: 'I1',
      name: 'Desk',
      description: 'Oak desk',
      attrs: {'color': 'brown', 'w': 120, 'h': 75},
      guids: ['g1', 'g2'],
    );
    await svc.upsertItem(item);

    var loaded = await svc.getItemById('I1');
    expect(loaded?.name, 'Desk');
    expect(loaded?.description, 'Oak desk');
    expect(loaded?.attrs['color'], 'brown');
    expect(loaded?.imageGuids, ['g1', 'g2']);

    // Update description and attrs
    await svc.upsertItem(item.copyWith(description: 'Refinished', attrs: {'color': 'black'}));
    loaded = await svc.getItemById('I1');
    expect(loaded?.description, 'Refinished');
    expect(loaded?.attrs['color'], 'black');
  });

  test('delete room cascades items; delete container sets item.containerId = null', () async {
    await seedLocationRoom();
    await svc.addContainer(container(id: 'C1'));

    await svc.addItem(item0(id: 'IR', name: 'RoomItem')); // room
    await svc.addItem(item0(id: 'IC', containerId: 'C1', name: 'Boxed')); // inside container

    // Delete the container: IC should become top-level in room (containerId == null)
    await svc.deleteContainer('C1');

    final postRoomItems = await svc.getItemsInRoom('R1');
    expect(postRoomItems.map((e) => e.id).toSet(), {'IR', 'IC'});
    expect(await svc.getItemsInContainer('C1'), isEmpty);

    // Now delete the room: all items should be gone
    await svc.deleteRoom('R1');
    expect(await svc.getItemsInRoom('R1'), isEmpty);
    expect(await svc.getItemById('IR'), isNull);
    expect(await svc.getItemById('IC'), isNull);
  });

  test('clearAllData wipes containers and items (streams go empty)', () async {
    await seedLocationRoom();
    await svc.addContainer(container(id: 'C1'));
    await svc.addItem(item0(id: 'I1'));
    await svc.addItem(item0(id: 'I2', containerId: 'C1'));

    final expectTopLevel = expectLater(
      svc.watchTopLevelContainers('R1'),
      emitsThrough(isA<List<Container>>().having((l) => l.length, 'after clear', 0)),
    );
    final expectItemsRoom = expectLater(
      svc.watchItemsInRoom('R1'),
      emitsThrough(isA<List<Item>>().having((l) => l.length, 'after clear', 0)),
    );

    await svc.clearAllData();

    expect(await svc.getTopLevelContainers('R1'), isEmpty);
    expect(await svc.getItemsInRoom('R1'), isEmpty);

    await expectTopLevel;
    await expectItemsRoom;
  });
}
