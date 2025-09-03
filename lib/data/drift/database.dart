// lib/data/drift/database.dart
// coverage:ignore-file
import 'package:drift/drift.dart';

import '../../domain/models/location_model.dart';
import '../../domain/models/room_model.dart';
import '../../domain/models/container_model.dart';
import '../../domain/models/item_model.dart';
import 'converters.dart';

part 'tables.dart';
part 'mappers.dart';
part 'daos.dart';
part 'database.g.dart';

@DriftDatabase(tables: [Locations, Rooms, Containers, Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(containers);
        await m.createTable(items);
      }
      // future migrations go here
    },
  );
}
