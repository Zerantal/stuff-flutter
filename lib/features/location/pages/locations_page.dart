// lib/features/location/pages/locations_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/sample_data_populator.dart';
import '../../../shared/image/image_ref.dart';
import '../../../shared/Widgets/confirmation_dialog.dart';
import '../../../shared/Widgets/context_action_menu.dart';
import '../../../shared/Widgets/empty_list_state.dart';
import '../../../shared/Widgets/gesture_wrapped_thumbnail.dart';
import '../../../shared/widgets/responsive_entity_list.dart';
import '../../../shared/widgets/skeleton_tile.dart';
import '../widgets/developer_drawer.dart';
import '../viewmodels/locations_view_model.dart';

final Logger _log = Logger('LocationsPage');

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  late final LocationsViewModel vm;

  @override
  void initState() {
    super.initState();
    vm = LocationsViewModel(
      dataService: context.read<IDataService>(),
      imageDataService: context.read<IImageDataService>(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useExtendedFab = width >= 720; // wide screens get an extended FAB

    return Scaffold(
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
      drawer: kDebugMode
          ? DeveloperDrawer(
              onPopulateSampleData: () async {
                final data = context.read<IDataService>();
                final images = context.read<IImageDataService>();
                // Perform the actual population (no ViewModel coupling here)
                await SampleDataPopulator(dataService: data, imageDataService: images).populate();
              },
            )
          : null,
      body: StreamBuilder<List<LocationListItem>>(
        stream: vm.locations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            // Skeletons while first batch loads
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (context, i) => const SkeletonTile(),
            );
          }

          final items = snapshot.data ?? const <LocationListItem>[];
          if (items.isEmpty) {
            return EmptyListState(
              onAdd: () => AppRoutes.locationsAdd.push(context),
              text: 'No locations found. Tap + to add one..',
              buttonText: 'Add First Location',
              buttonIcon: const Icon(Icons.add_home_outlined),
            );
          }

          return ResponsiveEntityList<LocationListItem>(
            minTileWidth: 300,
            items: items,
            onTap: (it) =>
                AppRoutes.rooms.push(context, pathParams: {'locationId': it.location.id}),
            thumbnailBuilder: (ctx, it) => GestureWrappedThumbnail(
              images: it.images,
              entityId: it.location.id,
              entityName: it.location.name,
              size: 80,
              placeholder: const ImageRef.asset('assets/images/location_placeholder.jpg'),
            ),
            descriptionBuilder: itemDescriptionBuilder,
            trailingBuilder: (ctx, it) => ContextActionMenu(
              onView: () =>
                  AppRoutes.rooms.push(context, pathParams: {'locationId': it.location.id}),
              onEdit: () =>
                  AppRoutes.locationsEdit.push(context, pathParams: {'locationId': it.location.id}),
              onDelete: () => _confirmDelete(context, vm, it),
            ),
          );
        },
      ),
      floatingActionButton: useExtendedFab
          ? FloatingActionButton.extended(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationsAdd.push(context),
              icon: const Icon(Icons.add_home_outlined),
              label: const Text('Add Location'),
            )
          : FloatingActionButton(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationsAdd.push(context),
              tooltip: 'Add Location',
              child: const Icon(Icons.add_home_outlined),
            ),
    );
  }

  Widget itemDescriptionBuilder(BuildContext context, LocationListItem item) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.location.name,
          style: theme.textTheme.titleLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if ((item.location.description ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              item.location.description!,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        if ((item.location.address ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.place_outlined, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    item.location.address!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Future<void> _confirmDelete(BuildContext context, LocationsViewModel vm, Location loc) async {
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
