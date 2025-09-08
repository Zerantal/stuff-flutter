// // lib/features/contents/repository/room_contents_repository.dart
//
// import 'dart:async';
//
// import '../../../domain/models/container_model.dart';
// import '../../../domain/models/item_model.dart';
// import '../../../services/contracts/data_service_interface.dart';
// import '../models/container_contents.dart';
// import '../models/room_contents.dart';
//
//
// class RoomContentsRepository {
//   final IDataService _data;
//   RoomContentsRepository(this._data);
//
//   /// Stream the contents for a room: top-level containers + items directly in the room.
//   Stream<RoomContents> watchRoomContents(String roomId) {
//     final sContainers = _data.watchTopLevelContainers(roomId);
//     final sItems = _data.watchItemsInRoom(roomId);
//
//     return _combineLatest2<List<Container>, List<Item>, RoomContents>(
//       sContainers,
//       sItems,
//           (containers, items) {
//         final sig = RoomContents.computeSignature(containers: containers, items: items);
//         return RoomContents(
//           roomId: roomId,
//           containers: containers,
//           items: items,
//           signature: sig,
//         );
//       },
//     ).distinct(_roomDistinct);
//   }
//
//   /// One-shot snapshot of room contents (first values of both streams).
//   Future<RoomContents> getRoomContents(String roomId) async {
//     final containers = await _data.watchTopLevelContainers(roomId).first;
//     final items = await _data.watchItemsInRoom(roomId).first;
//     return RoomContents(
//       roomId: roomId,
//       containers: containers,
//       items: items,
//       signature: RoomContents.computeSignature(containers: containers, items: items),
//     );
//   }
//
//   /// Stream the contents for a specific container: child containers + items in it.
//   Stream<ContainerContents> watchContainerContents(String containerId) {
//     final sChild = _data.watchChildContainers(containerId);
//     final sItems = _data.watchItemsInContainer(containerId);
//
//     return _combineLatest2<List<Container>, List<Item>, ContainerContents>(
//       sChild,
//       sItems,
//           (child, items) {
//         final sig = ContainerContents.computeSignature(childContainers: child, items: items);
//         return ContainerContents(
//           containerId: containerId,
//           childContainers: child,
//           items: items,
//           signature: sig,
//         );
//       },
//     ).distinct(_containerDistinct);
//   }
//
//   /// One-shot snapshot of container contents (first values of both streams).
//   Future<ContainerContents> getContainerContents(String containerId) async {
//     final child = await _data.watchChildContainers(containerId).first;
//     final items = await _data.watchItemsInContainer(containerId).first;
//     return ContainerContents(
//       containerId: containerId,
//       childContainers: child,
//       items: items,
//       signature: ContainerContents.computeSignature(childContainers: child, items: items),
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // Distinct helpers to avoid redundant rebuilds when nothing meaningful changed
//   // ---------------------------------------------------------------------------
//
//   bool _roomDistinct(RoomContents a, RoomContents b) => a.signature == b.signature;
//   bool _containerDistinct(ContainerContents a, ContainerContents b) =>
//       a.signature == b.signature;
//
//   // ---------------------------------------------------------------------------
//   // Local combineLatest2 (no extra deps)
//   // Emits whenever either source emits, after both have produced at least one.
//   // ---------------------------------------------------------------------------
//
//   static Stream<R> _combineLatest2<A, B, R>(
//       Stream<A> sa,
//       Stream<B> sb,
//       R Function(A a, B b) combiner,
//       ) {
//     late StreamController<R> controller;
//     A? lastA;
//     B? lastB;
//     var hasA = false, hasB = false;
//     StreamSubscription<A>? subA;
//     StreamSubscription<B>? subB;
//
//     void emitIfReady() {
//       if (hasA && hasB && !controller.isClosed) {
//         controller.add(combiner(lastA as A, lastB as B));
//       }
//     }
//
//     controller = StreamController<R>(
//       sync: true,
//       onListen: () {
//         subA = sa.listen((a) {
//           lastA = a;
//           hasA = true;
//           emitIfReady();
//         }, onError: controller.addError, onDone: () {
//           // If either completes early, we still keep the other until cancel.
//         });
//
//         subB = sb.listen((b) {
//           lastB = b;
//           hasB = true;
//           emitIfReady();
//         }, onError: controller.addError, onDone: () {});
//       },
//       onPause: () {
//         subA?.pause();
//         subB?.pause();
//       },
//       onResume: () {
//         subA?.resume();
//         subB?.resume();
//       },
//       onCancel: () async {
//         await subA?.cancel();
//         await subB?.cancel();
//       },
//     );
//
//     return controller.stream;
//   }
// }
