// lib/features/location/pages/locations_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../shared/image/image_ref.dart';
import '../../../domain/models/location_model.dart';
import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_route_ext.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../viewmodels/locations_view_model.dart';
import '../../../shared/Widgets/image_thumb.dart';
import '../../dev_tools/pages/database_inspector_page.dart';

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
      drawer: kDebugMode ? _DeveloperDrawer(vm: vm) : null,
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
                itemBuilder: (context, i) => const _SkeletonTile(),
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

            return _ResponsiveLocations(
              items: items,
              onView: (loc) => AppRoutes.rooms.push(context, pathParams: {'locationId': loc.id}),
              onEdit: (loc) =>
                  AppRoutes.locationsEdit.push(context, pathParams: {'locationId': loc.id}),
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
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
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
              leading: const Icon(Icons.manage_search),
              title: const Text('Database Inspector'),
              subtitle: const Text('Browse records (debug)'),
              onTap: () {
                final nav = Navigator.of(context); // capture before any await
                if (Navigator.canPop(context)) nav.pop(); // close drawer
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => Provider<IDataService>.value(
                      // Pass through the same IDataService already in scope
                      value: context.read<IDataService>(),
                      child: const DatabaseInspectorPage(),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Reset DB with Sample Data'),
              onTap: () async {
                // capture
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                if (nav.canPop()) nav.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Resetting database…')));

                try {
                  await vm.resetWithSampleData();
                  messenger.showSnackBar(const SnackBar(content: Text('Sample data loaded')));
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
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('location_card_${location.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onView(location),
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
                  const ImageRef.asset('assets/images/location_placeholder.jpg'),
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
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((location.description ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          location.description!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if ((location.address ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.address!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<int>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 0) onEdit(location);
                  if (v == 1) onView(location);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 0, child: Text('Edit')),
                  PopupMenuItem(value: 1, child: Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive list: list on phones, grid on wider screens.
class _ResponsiveLocations extends StatelessWidget {
  const _ResponsiveLocations({required this.items, required this.onView, required this.onEdit});

  final List<LocationListItem> items;
  final void Function(Location) onView;
  final void Function(Location) onEdit;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useGrid = width >= 720;

    if (!useGrid) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return _LocationCard(
            location: item.location,
            image: item.image,
            onView: onView,
            onEdit: onEdit,
          );
        },
      );
    }

    final columns = width >= 1100 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisExtent: 132,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _GridLocationCard(
          location: item.location,
          image: item.image,
          onView: onView,
          onEdit: onEdit,
        );
      },
    );
  }
}

class _GridLocationCard extends StatelessWidget {
  const _GridLocationCard({
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
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onView(location),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ImageThumb(
                image: image,
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(8),
                placeholderWidget: buildImage(
                  const ImageRef.asset('assets/images/location_placeholder.jpg'),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      location.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((location.address ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.place_outlined, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location.address!,
                                style: theme.textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<int>(
                tooltip: 'More',
                onSelected: (v) {
                  if (v == 0) onEdit(location);
                  if (v == 1) onView(location);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(value: 0, child: Text('Edit')),
                  PopupMenuItem(value: 1, child: Text('View')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Simple skeleton placeholder row used during initial load.
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    Widget box(double w, double h, {BorderRadius? r}) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: c, borderRadius: r ?? BorderRadius.circular(6)),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          box(80, 80, r: BorderRadius.circular(8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(double.infinity, 16),
                const SizedBox(height: 8),
                box(180, 14),
                const SizedBox(height: 6),
                box(120, 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
