// // lib/features/contents/models/container_contents.dart
//
// import 'package:meta/meta.dart';
//
// import '../../../domain/models/container_model.dart';
// import '../../../domain/models/item_model.dart';
//
// /// Immutable DTO for the "Container Contents" screen:
// /// - child containers under this container
// /// - items inside this container
// @immutable
// class ContainerContents {
//   final String containerId;
//   final List<Container> childContainers;
//   final List<Item> items;
//   final int signature;
//
//   const ContainerContents({
//     required this.containerId,
//     required this.childContainers,
//     required this.items,
//     required this.signature,
//   });
//
//   static int computeSignature({
//     required List<Container> childContainers,
//     required List<Item> items,
//   }) {
//     Object sigContainers = Object.hashAll(
//       childContainers.map((c) => Object.hash(
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
//       'ContainerContents(containerId:$containerId child:${childContainers.length} items:${items.length})';
// }
