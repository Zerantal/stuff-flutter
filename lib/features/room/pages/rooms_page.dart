// lib/features/room/pages/rooms_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes_ext.dart';
import '../../../app/routing/app_routes.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/context_action_menu.dart';
import '../../../shared/widgets/gesture_wrapped_thumbnail.dart';
import '../../../shared/widgets/entity_description.dart';
import '../../../shared/widgets/responsive_entity_list.dart';
import '../../../shared/widgets/skeleton_entity_list.dart';
import '../viewmodels/rooms_view_model.dart';
import '../../../shared/widgets/empty_list_state.dart';

final _log = Logger('RoomsPage');

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useExtendedFab = width >= 720;
    final vm = context.read<RoomsViewModel>();

    return Scaffold(
      key: const ValueKey('RoomsPage'),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rooms'),
            if (vm.locationName != null)
              Text(vm.locationName!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: _buildBody(vm),
      floatingActionButton: useExtendedFab
          ? FloatingActionButton.extended(
              key: const ValueKey('add_room_fab'),
              heroTag: 'roomsPageFAB',
              onPressed: () =>
                  AppRoutes.roomAdd.push(context, pathParams: {'locationId': vm.locationId}),
              icon: const Icon(Icons.add_outlined),
              label: const Text('Add Room'),
            )
          : FloatingActionButton(
              key: const ValueKey('add_room_fab'),
              heroTag: 'roomsPageFAB',
              onPressed: () =>
                  AppRoutes.roomAdd.push(context, pathParams: {'locationId': vm.locationId}),
              tooltip: 'Add Room',
              child: const Icon(Icons.add_outlined),
            ),
    );
  }

  Widget _buildBody(RoomsViewModel vm) {
    return StreamBuilder<List<RoomListItem>>(
      stream: vm.rooms,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonEntityList(numRows: 2);
        }

        final items = snapshot.data ?? const <RoomListItem>[];
        if (items.isEmpty) {
          return EmptyListState(
            onAdd: () => AppRoutes.roomAdd.push(context, pathParams: {'locationId': vm.locationId}),
            text: "No rooms yet\nAdd your first room for this location",
            buttonText: "Add room",
            buttonIcon: const Icon(Icons.add_outlined),
          );
        }

        GestureWrappedThumbnail thumbnailBuilder(
          BuildContext context,
          RoomListItem item, {
          BoxFit fit = BoxFit.cover,
        }) => GestureWrappedThumbnail(
          images: item.images,
          entityId: item.room.id,
          entityName: item.room.name,
          fit: fit,
          placeholder: const ImageRef.asset('assets/images/image_placeholder.png'),
        );

        return ResponsiveEntityList<RoomListItem>(
          gridBodyTargetHeight: 80,
          items: items,
          onTap: (it) => AppRoutes.roomContentsAlias.push(
            context,
            pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
          ),
          headerBuilder: (ctx, it) => thumbnailBuilder(ctx, it),
          bodyBuilder: (ctx, it) =>
              EntityDescription(title: it.room.name, description: it.room.description),
          trailingBuilder: (ctx, it) => ContextActionMenu(
            onView: () => AppRoutes.roomContentsAlias.push(
              context,
              pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
            ),
            onEdit: () => AppRoutes.roomEdit.push(
              ctx,
              pathParams: {'locationId': vm.locationId, 'roomId': it.room.id},
            ),
            onDelete: () => _confirmDelete(context, vm, it),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, RoomsViewModel vm, RoomListItem rm) async {
    // capture before async gap to avoid use_build_context_synchronously lint
    final messenger = ScaffoldMessenger.of(context);

    final ok = await ConfirmationDialog.show(
      context,
      title: 'Delete location?',
      message: 'This will permanently delete this location and its photos.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      danger: true,
    );

    if (ok == true) {
      try {
        await vm.deleteRoom(rm.room.id);
        messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete location', e, s);
      }
    }
  }
}
