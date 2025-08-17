import 'package:drift/drift.dart';

import '../../domain/models/location_model.dart';
import '../../domain/models/room_model.dart';
import 'converters.dart';

part 'tables.dart';
part 'mappers.dart';
part 'daos.dart';
part 'database.g.dart';

@DriftDatabase(tables: [Locations, Rooms])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    beforeOpen: (details) async {
      // Ensure FK cascading works in all envs (including in-memory tests)
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (m, from, to) async {
      // add future migrations
    },
  );
}
