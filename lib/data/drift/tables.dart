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

@DataClassName('ContainerRow')
class Containers extends Table {
  TextColumn get id => text()();

  /// Belongs to a room
  TextColumn get roomId => text().references(Rooms, #id, onDelete: KeyAction.cascade)();

  /// Optional nesting
  TextColumn get parentContainerId =>
      text().nullable().references(Containers, #id, onDelete: KeyAction.cascade)();

  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get imageGuidsJson =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  /// Manual ordering
  IntColumn get positionIndex => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ItemRow')
class Items extends Table {
  TextColumn get id => text()();

  /// Anchor to room for fast filtering
  TextColumn get roomId => text().references(Rooms, #id, onDelete: KeyAction.cascade)();

  /// Null => item is directly in the room
  TextColumn get containerId =>
      text().nullable().references(Containers, #id, onDelete: KeyAction.setNull)();

  TextColumn get name => text().nullable()();
  TextColumn get description => text().nullable()();

  /// User-defined fields as JSON object
  TextColumn get attrsJson =>
      text().map(const JsonMapConverter()).withDefault(const Constant('{}'))();

  TextColumn get imageGuidsJson =>
      text().map(const StringListConverter()).withDefault(const Constant('[]'))();

  /// Order within container/room
  IntColumn get positionIndex => integer().nullable()();

  /// Soft delete / hide
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
