// lib/features/location/pages/locations_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../../shared/widgets/context_action_menu.dart';
import '../../../shared/widgets/empty_list_state.dart';
import '../../../shared/widgets/entity_description.dart';
import '../../../shared/widgets/entity_tile_theme.dart';
import '../../../shared/widgets/gesture_wrapped_thumbnail.dart';
import '../../../shared/widgets/responsive_entity_list.dart';
import '../../../shared/widgets/skeleton_entity_list.dart';
import '../../../App/theme.dart';
import '../widgets/developer_drawer.dart';
import '../viewmodels/locations_view_model.dart';

final Logger _log = Logger('LocationsPage');

class LocationsPage extends StatelessWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useExtendedFab = width >= 720; // wide screens get an extended FAB
    final vm = context.read<LocationsViewModel>();

    return Scaffold(
      key: const ValueKey('LocationsPage'),
      appBar: AppBar(
        title: const Text('Locations'),
        leading: kDebugMode
            ? Builder(
                builder: (appBarCtx) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Developer Options',
                  onPressed: () => Scaffold.of(appBarCtx).openDrawer(),
                ),
              )
            : null,
      ),
      drawer: kDebugMode ? const DeveloperDrawer() : null,
      body: StreamBuilder<List<LocationListItem>>(
        stream: vm.locations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            // Skeletons while first batch loads
            return const SkeletonEntityList(count: 6, numRows: 3);
          }

          final items = snapshot.data ?? const <LocationListItem>[];
          if (items.isEmpty) {
            return EmptyListState(
              onAdd: () => AppRoutes.locationAdd.push(context),
              text: 'No locations found. Tap + to add one.',
              buttonText: 'Add First Location',
              buttonIcon: const Icon(Icons.add_home_outlined),
            );
          }

          GestureWrappedThumbnail thumbnailBuilder(BuildContext context, LocationListItem item) =>
              GestureWrappedThumbnail(
                images: item.images,
                entityId: item.location.id,
                entityName: item.location.name,
                size: 80,
                borderRadius: AppRadius.md,
                placeholder: const ImageRef.asset('assets/images/image_placeholder.png'),
              );

          return ResponsiveEntityList<LocationListItem>(
            density: EntityTileDensity.roomy,
            items: items,
            onTap: (it) => AppRoutes.roomsForLocation.push(
              context,
              pathParams: {'locationId': it.location.id},
              extra: it.location.name,
            ),
            headerBuilder: thumbnailBuilder,
            bodyBuilder: _itemDescriptionBuilder,
            trailingBuilder: (ctx, it) => ContextActionMenu(
              onView: () => AppRoutes.roomsForLocation.push(
                context,
                pathParams: {'locationId': it.location.id},
                extra: it.location.name,
              ),
              onEdit: () =>
                  AppRoutes.locationEdit.push(context, pathParams: {'locationId': it.location.id}),
              onDelete: () => _confirmDelete(context, vm, it),
            ),
            gridBodyTargetHeight: 100,
          );
        },
      ),
      floatingActionButton: useExtendedFab
          ? FloatingActionButton.extended(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationAdd.push(context),
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Add Location'),
            )
          : FloatingActionButton(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationAdd.push(context),
              tooltip: 'Add Location',
              child: const Icon(Icons.add_home_outlined),
            ),
    );
  }

  /// Renders the body content of a location card
  Widget _itemDescriptionBuilder(BuildContext context, LocationListItem item) {
    final theme = Theme.of(context);

    return EntityDescription(
      title: item.location.name,
      description: item.location.description,
      extra: (item.location.address?.isNotEmpty ?? false)
          ? Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: theme.iconTheme.size ?? 14,
                  color: theme.iconTheme.color?.withValues(alpha: 0.7), // replaces withOpacity
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    item.location.address!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    LocationsViewModel vm,
    LocationListItem loc,
  ) async {
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
        await vm.deleteLocationById(loc.location.id);
        messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
      } catch (e, s) {
        messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
        _log.severe('Failed to delete location', e, s);
      }
    }
  }
}
