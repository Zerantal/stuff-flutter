import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:clock/clock.dart';

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

  Future<void> seed() async {
    await svc.addLocation(Location(id: 'L1', name: 'Home'));
    await svc.addRoom(Room(id: 'R1', locationId: 'L1', name: 'Kitchen'));
  }

  group('timestamps via package:clock', () {
    test('Item createdAt/updatedAt on add + update + archive respect fixed clocks', () async {
      await seed();

      final t1 = DateTime.utc(2025, 1, 1, 12, 0, 0);
      final t2 = DateTime.utc(2025, 1, 1, 12, 5, 0);
      final t3 = DateTime.utc(2025, 1, 1, 12, 10, 0);

      // Add (createdAt=updatedAt=t1)
      await withClock(Clock.fixed(t1), () async {
        await svc.addItem(Item(id: 'I1', roomId: 'R1', name: 'Mug'));
      });

      var a = await svc.getItemById('I1');
      expect(a, isNotNull);
      expect(a!.createdAt, t1);
      expect(a.updatedAt, t1);

      // Update (updatedAt=t2; createdAt unchanged)
      await withClock(Clock.fixed(t2), () async {
        await svc.updateItem(a.copyWith(name: 'Mug v2'));
      });

      var b = await svc.getItemById('I1');
      expect(b, isNotNull);
      expect(b!.createdAt, t1, reason: 'createdAt must remain unchanged after update');
      expect(b.updatedAt, t2, reason: 'updatedAt must be set to t2');

      // Archive (updatedAt=t3)
      await withClock(Clock.fixed(t3), () async {
        await svc.setItemArchived('I1', true);
      });

      var c = await svc.getItemById('I1');
      expect(c, isNotNull);
      expect(c!.updatedAt, t3);
      expect(c.isArchived, isTrue);
      expect(c.createdAt, t1);
    });

    test('Container createdAt/updatedAt on add + update respect fixed clocks', () async {
      await seed();

      final t1 = DateTime.utc(2025, 2, 1, 8, 0, 0);
      final t2 = DateTime.utc(2025, 2, 1, 8, 30, 0);

      // Add
      await withClock(Clock.fixed(t1), () async {
        await svc.addContainer(Container(id: 'C1', roomId: 'R1', name: 'Box'));
      });

      var c1 = await svc.getContainerById('C1');
      expect(c1, isNotNull);
      expect(c1!.createdAt, t1);
      expect(c1.updatedAt, t1);

      // Update
      await withClock(Clock.fixed(t2), () async {
        await svc.updateContainer(c1.copyWith(description: 'Plastic storage box'));
      });

      var c2 = await svc.getContainerById('C1');
      expect(c2, isNotNull);
      expect(c2!.createdAt, t1);
      expect(c2.updatedAt, t2);
      expect(c2.description, 'Plastic storage box');
    });

    test('Upsert sets createdAt when null and bumps updatedAt each call', () async {
      await seed();

      final t1 = DateTime.utc(2025, 3, 10, 9, 0, 0);
      final t2 = DateTime.utc(2025, 3, 10, 9, 1, 0);

      // Upsert new (acts like add)
      await withClock(Clock.fixed(t1), () async {
        await svc.upsertItem(Item(id: 'I2', roomId: 'R1', name: 'Chair'));
      });

      var i1 = await svc.getItemById('I2');
      expect(i1, isNotNull);
      expect(i1!.createdAt, t1);
      expect(i1.updatedAt, t1);

      // Upsert existing (acts like update)
      await withClock(Clock.fixed(t2), () async {
        await svc.upsertItem(i1.copyWith(description: 'Wooden chair'));
      });

      var i2 = await svc.getItemById('I2');
      expect(i2, isNotNull);
      expect(i2!.createdAt, t1);
      expect(i2.updatedAt, t2);
      expect(i2.description, 'Wooden chair');
    });
  });
}
