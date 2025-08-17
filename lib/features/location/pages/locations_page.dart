// lib/features/location/pages/locations_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/location_model.dart';
import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_route_ext.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/sample_data_populator.dart';
import '../viewmodels/locations_view_model.dart';
import '../../../shared/Widgets/confirmation_dialog.dart';
import '../widgets/developer_drawer.dart';
import '../widgets/responsive_list.dart';
import '../widgets/skeleton_tile.dart';

final Logger _log = Logger('LocationsPage');

class LocationsPage extends StatelessWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LocationsViewModel(
        dataService: ctx.read<IDataService>(),
        imageDataService: ctx.read<IImageDataService>(),
      ),
      child: const LocationsView(),
    );
  }
}

class LocationsView extends StatelessWidget {
  const LocationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.read<LocationsViewModel>();
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
              onPopulated: vm.refresh,
            )
          : null,
      body: RefreshIndicator(
        key: const Key('locations_refresh_indicator'),
        onRefresh: vm.refresh,
        child: StreamBuilder<List<LocationListItem>>(
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
            if (snapshot.hasError) {
              return _ErrorState(message: 'Error loading locations', onRetry: vm.refresh);
            }

            final items = snapshot.data ?? const <LocationListItem>[];
            if (items.isEmpty) {
              return _EmptyState(
                onAdd: () {
                  AppRoutes.locationsAdd.push(context);
                },
              );
            }

            return ResponsiveLocations(
              items: items,
              onView: (loc) => AppRoutes.rooms.push(context, pathParams: {'locationId': loc.id}),
              onEdit: (loc) =>
                  AppRoutes.locationsEdit.push(context, pathParams: {'locationId': loc.id}),
              onDelete: (loc) => _confirmDelete(context, vm, loc),
            );
          },
        ),
      ),
      floatingActionButton: useExtendedFab
          ? FloatingActionButton.extended(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationsAdd.push(context),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Location'),
            )
          : FloatingActionButton(
              key: const ValueKey('add_location_fab'),
              heroTag: 'locationsPageFAB',
              onPressed: () => AppRoutes.locationsAdd.push(context),
              tooltip: 'Add Location',
              child: const Icon(Icons.add_location_alt_outlined),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No locations found. Tap + to add one or pull down to refresh.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add First Location'),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDelete(BuildContext context, LocationsViewModel vm, Location loc) async {
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
      await vm.deleteLocationById(loc.id);
      messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
    } catch (e, s) {
      messenger.showSnackBar(const SnackBar(content: Text('Delete failed')));
      _log.severe('Failed to delete location', e, s);
    }
  }
}
