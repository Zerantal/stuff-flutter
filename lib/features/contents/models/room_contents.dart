// // lib/features/contents/models/room_contents.dart
//
// import 'package:meta/meta.dart';
//
// import '../../../domain/models/container_model.dart';
// import '../../../domain/models/item_model.dart';
//
// /// Immutable DTO for the "Room Contents" screen:
// /// - top-level containers in the room (no parent)
// /// - items directly in the room (containerId == null, not archived)
// @immutable
// class RoomContents {
//   final String roomId;
//   final List<Container> containers;
//   final List<Item> items;
//
//   /// A compact token so consumers can `distinct()` cheaply.
//   /// Changes if *identity/order/updatedAt/positionIndex* of either list changes.
//   final int signature;
//
//   const RoomContents({
//     required this.roomId,
//     required this.containers,
//     required this.items,
//     required this.signature,
//   });
//
//   /// Build a lightweight signature from ids + important fields that affect UI.
//   static int computeSignature({
//     required List<Container> containers,
//     required List<Item> items,
//   }) {
//     Object sigContainers = Object.hashAll(
//       containers.map((c) => Object.hash(
//         c.id,
//         c.updatedAt.microsecondsSinceEpoch,
//         c.positionIndex ?? -1,
//       )),
//     );
//     Object sigItems = Object.hashAll(
//       items.map((i) => Object.hash(
//         i.id,
//         i.updatedAt.microsecondsSinceEpoch,
//         i.positionIndex ?? -1,
//         i.isArchived ? 1 : 0,
//       )),
//     );
//     return Object.hash(sigContainers, sigItems);
//   }
//
//   @override
//   String toString() =>
//       'RoomContents(roomId:$roomId containers:${containers.length} items:${items.length})';
// }
