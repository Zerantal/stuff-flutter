// lib/pages/locations_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../core/helpers/image_ref.dart';
import '../models/location_model.dart';
import '../routing/app_routes.dart';
import '../routing/app_route_ext.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../viewmodels/locations_view_model.dart';
import '../widgets/image_thumb.dart';

// final Logger _log = Logger('LocationsPage');

class LocationsPage extends StatelessWidget {
  const LocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => LocationsViewModel(
        dataService: ctx.read<IDataService>(),
        imageDataService: ctx.read<IImageDataService>(),
      ),
      child: const _LocationsView(),
    );
  }
}

class _LocationsView extends StatelessWidget {
  const _LocationsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LocationsViewModel>();
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
      drawer: kDebugMode ? _DeveloperDrawer(vm: vm) : null,
      body: RefreshIndicator(
        key: const Key('locations_refresh_indicator'),
        onRefresh: vm.refresh,
        child: StreamBuilder<List<LocationListItem>>(
          stream: vm.locations,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(
                    key: Key('locations_waiting_spinner'),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Error loading locations',
                onRetry: vm.refresh,
              );
            }

            final items = snapshot.data ?? const <LocationListItem>[];
            if (items.isEmpty) {
              return _EmptyState(
                onAdd: () {
                  AppRoutes.locationsAdd.go(context);
                },
              );
            }

            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return _LocationCard(
                  location: item.location,
                  image: item.image, // ImageRef? (null => placeholder)
                  onView: (loc) => AppRoutes.rooms.go(
                    context,
                    pathParams: {'locationId': loc.id},
                  ),
                  onEdit: (loc) => AppRoutes.locationsEdit.go(
                    context,
                    pathParams: {'locationId': loc.id},
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_location_fab'),
        heroTag: 'locationsPageFAB',
        onPressed: () => AppRoutes.locationsAdd.go(context),
        tooltip: 'Add Location',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }
}

class _DeveloperDrawer extends StatelessWidget {
  const _DeveloperDrawer({required this.vm});
  final LocationsViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'Developer Options',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Reset DB with Sample Data'),
              onTap: () async {
                // capture
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                if (nav.canPop()) nav.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Resetting database…')),
                );

                try {
                  await vm.resetWithSampleData();
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Sample data loaded')),
                  );
                } catch (_) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Failed to load sample data')),
                  );
                }
              },
            ),
          ],
        ),
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

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.image,
    required this.onView,
    required this.onEdit,
  });

  final Location location;
  final ImageRef? image;
  final void Function(Location) onView;
  final void Function(Location) onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('location_card_${location.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageThumb(
              key: Key('location_thumb_${location.id}'),
              image: image, // null => placeholderWidget shown
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(8),
              placeholderWidget: buildImage(
                const ImageRef.asset('Assets/images/location_placeholder.jpg'),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if ((location.description ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        location.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if ((location.address ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Address: ${location.address!}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        key: Key('view_location_${location.id}'),
                        icon: const Icon(Icons.meeting_room_outlined),
                        label: const Text('View'),
                        onPressed: () => onView(location),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: Key('edit_location_${location.id}'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        onPressed: () => onEdit(location),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
