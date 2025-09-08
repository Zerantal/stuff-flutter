import '../../domain/models/container_model.dart';

abstract class IContainerStore {
  // Streams
  // watch top level containers in room
  Stream<List<Container>> watchRoomContainers(String roomId);
  // watch top level containers inside a container
  Stream<List<Container>> watchChildContainers(String parentContainerId);
  // watch all top-level containers in all rooms inside a location
  Stream<List<Container>> watchLocationContainers(String locationId);
  // watch all top-level containers in all rooms inside all locations
  Stream<List<Container>> watchAllContainers();

  // One-shot queries
  Future<List<Container>> getRoomContainers(String roomId);
  Future<List<Container>> getChildContainers(String parentContainerId);
  Future<List<Container>> getLocationContainers(String locationId);
  Future<List<Container>> getAllContainers();
  Future<Container?> getContainerById(String id);

  // Commands
  Future<Container> addContainer(Container container);
  Future<Container> updateContainer(Container container);
  Future<Container> upsertContainer(Container container);
  Future<void> deleteContainer(String id);
}
