part of 'database.dart';

@DataClassName('LocationRow')
class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get imageGuidsJson =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RoomRow')
@TableIndex(name: 'idx_rooms_locationId', columns: {#locationId})
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get locationId => text().references(
    Locations,
    #id,
    onDelete: KeyAction.cascade, // cascade rooms when a location is deleted
  )();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imageGuidsJson =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
