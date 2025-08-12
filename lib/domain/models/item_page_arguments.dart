// lib/domain/models/item_page_arguments.dart

// TODO: remove

// A class to hold arguments for the ItemsPage route.
// This is often cleaner than passing a Map directly.
class ItemPageArguments {
  final String locationName;
  final String locationId;
  final String roomName;
  final String roomId;
  final String containerName;
  final String? containerId; // Make containerId optional if name is primary key for now

  ItemPageArguments({
    required this.locationName,
    required this.locationId,
    required this.roomName,
    required this.roomId,
    required this.containerName,
    this.containerId, // This should be the actual ID from your data model
  });
}
