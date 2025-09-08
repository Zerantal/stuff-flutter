// lib/features/contents/viewmodels/contents_view_model.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../services/contracts/data_service_interface.dart';
import '../../../domain/models/container_model.dart' as dm;
import '../../../domain/models/item_model.dart' as dm;
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../shared/image/image_ref.dart';

final Logger _log = Logger('ContentsViewModel');

class ContainerListItem {
  final dm.Container container;
  final List<ImageRef> images;
  const ContainerListItem({required this.container, required this.images});
}

class ItemListItem {
  final dm.Item item;
  final List<ImageRef> images; // empty => placeholder in the view
  const ItemListItem({required this.item, required this.images});
}

/// Scope for what the page should display.
sealed class ContentsScope {
  const ContentsScope();
  const factory ContentsScope.all() = _AllScope;
  const factory ContentsScope.location(String locationId) = _LocationScope;
  const factory ContentsScope.room(String roomId) = _RoomScope;
  const factory ContentsScope.container(String containerId) = _ContainerScope;

  T map<T>({
    required T Function() all,
    required T Function(String locationId) location,
    required T Function(String roomId) room,
    required T Function(String containerId) container,
  }) {
    final self = this;
    if (self is _AllScope) return all();
    if (self is _LocationScope) return location(self.locationId);
    if (self is _RoomScope) return room(self.roomId);
    if (self is _ContainerScope) return container(self.containerId);
    throw StateError('Unknown ContentsScope $self');
  }
}

class _AllScope extends ContentsScope {
  const _AllScope();
}

class _LocationScope extends ContentsScope {
  const _LocationScope(this.locationId);
  final String locationId;
}

class _RoomScope extends ContentsScope {
  const _RoomScope(this.roomId);
  final String roomId;
}

class _ContainerScope extends ContentsScope {
  const _ContainerScope(this.containerId);
  final String containerId;
}

/// ViewModel that wires the correct pair of streams based on [scope].
class ContentsViewModel extends ChangeNotifier {
  ContentsViewModel({
    required IDataService dataService,
    required IImageDataService imageDataService,
    required this.scope,
  }) : _data = dataService,
       _imageDataService = imageDataService {
    _initStreams();
  }

  final IDataService _data;
  final IImageDataService _imageDataService;
  final ContentsScope scope;

  late final Stream<List<ContainerListItem>> containersStream;
  late final Stream<List<ItemListItem>> itemsStream;

  String get title => scope.map(
    all: () => 'All Contents',
    location: (_) => 'Location Contents',
    room: (_) => 'Room Contents',
    container: (_) => 'Container Contents',
  );

  /// Human-ish hint below the title.
  String? get subtitle => scope.map(
    all: () => 'All containers and items',
    location: (id) => 'Location: $id',
    room: (id) => 'Room: $id',
    container: (id) => 'Container: $id',
  );

  void _initStreams() {
    containersStream = scope
        .map(
          all: () => _data.watchAllContainers(),
          location: (locationId) => _data.watchLocationContainers(locationId),
          room: (roomId) => _data.watchRoomContainers(roomId),
          container: (containerId) => _data.watchChildContainers(containerId),
        )
        .map((list) => list.map(_toContainerListItem).toList(growable: false))
        .handleError((e, s) {
          _log.severe('containers stream error', e, s);
        });

    itemsStream = scope
        .map(
          all: () => _data.watchAllItems(),
          location: (locationId) => _data.watchLocationItems(locationId),
          room: (roomId) => _data.watchRoomItems(roomId),
          container: (containerId) => _data.watchContainerItems(containerId),
        )
        .map((list) => list.map(_toItemListItem).toList(growable: false))
        .handleError((e, s) {
          _log.severe('items stream error', e, s);
        });
  }

  Future<void> deleteContainer(String id) async {
    // Todo: delete container
    _log.fine('deleteContainer called for $id');
  }

  // ---- internals -----------------------------------------------------------

  // Build list item with zero-I/O image refs for smooth scrolling.
  ContainerListItem _toContainerListItem(dm.Container container) {
    final guids = container.imageGuids;
    final refs = _imageDataService.refsForGuids(guids);
    return ContainerListItem(container: container, images: refs);
  }

  ItemListItem _toItemListItem(dm.Item item) {
    final guids = item.imageGuids;
    final refs = _imageDataService.refsForGuids(guids);
    return ItemListItem(item: item, images: refs);
  }
}

/// Convenience factory for Provider wiring from a BuildContext with IDataService.
class ContentsVmFactory {
  static ContentsViewModel fromContext(BuildContext ctx, {required ContentsScope scope}) {
    final data = ctx.read<IDataService>();
    final imageDataService = ctx.read<IImageDataService>();
    return ContentsViewModel(dataService: data, imageDataService: imageDataService, scope: scope);
  }
}
