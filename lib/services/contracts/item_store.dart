import '../../domain/models/item_model.dart';

abstract class IItemStore {
  // Streams
  Stream<List<Item>> watchItemsInRoom(String roomId);
  Stream<List<Item>> watchItemsInContainer(String containerId);

  // One-shot queries
  Future<List<Item>> getItemsInRoom(String roomId);
  Future<List<Item>> getItemsInContainer(String containerId);
  Future<Item?> getItemById(String id);

  // Commands
  Future<Item> addItem(Item item);
  Future<Item> updateItem(Item item);
  Future<Item> upsertItem(Item item);
  Future<void> deleteItem(String id);
  Future<void> setItemArchived(String id, bool archived);
}
