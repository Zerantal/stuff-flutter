import '../../domain/models/room_model.dart';

abstract class IRoomStore {
  // Streams
  Stream<List<Room>> getRoomsStream(String locationId);

  // Queries / commands
  Future<List<Room>> getRoomsForLocation(String locationId);
  Future<Room?> getRoomById(String id);
  Future<Room> addRoom(Room room);
  Future<Room> updateRoom(Room room); // may move location
  Future<void> deleteRoom(String id);
}
