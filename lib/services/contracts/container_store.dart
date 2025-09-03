import '../../domain/models/container_model.dart';

abstract class IContainerStore {
  // Streams
  Stream<List<Container>> watchTopLevelContainers(String roomId);
  Stream<List<Container>> watchChildContainers(String parentContainerId);

  // One-shot queries
  Future<List<Container>> getTopLevelContainers(String roomId);
  Future<List<Container>> getChildContainers(String parentContainerId);
  Future<Container?> getContainerById(String id);

  // Commands
  Future<Container> addContainer(Container container);
  Future<Container> updateContainer(Container container);
  Future<Container> upsertContainer(Container container);
  Future<void> deleteContainer(String id);
}
