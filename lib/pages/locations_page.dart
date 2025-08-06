// lib/locations_page.dart
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

// services and models
import '../services/image_data_service_interface.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../routing/app_routes.dart';
import '../services/utils/sample_data_populator.dart';

final Logger _logger = Logger('LocationsPage');

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  late IDataService _dataService;
  Stream<List<Location>>? _locationsStream;

  @override
  void initState() {
    super.initState();
    _dataService = Provider.of<IDataService>(context, listen: false);
    _locationsStream = _dataService.getLocationsStream();
    _logger.info("LocationsPage: Subscribed to locations stream.");
  }

  Future<void> _handleRefresh() async {
    _logger.info("Handling refresh via RefreshIndicator...");
    if (mounted) {
      await _dataService.getAllLocations();
    }
    _logger.info("RefreshIndicator completed.");
  }

  void _addNewLocation() {
    _logger.info("Navigating to add new location page.");
    Navigator.of(context).pushNamed(AppRoutes.addLocation);
  }

  void _editLocationInfo(Location location) {
    _logger.info("Navigating to edit location: ${location.name}");
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.editLocation, arguments: location);
  }

  void _viewLocationContents(Location location) {
    _logger.info("Navigating to view contents for location: ${location.name}");
    Navigator.of(context).pushNamed(AppRoutes.rooms, arguments: location);
  }

  // --- Start of Developer Tools Logic ---
  Future<void> _resetDatabaseWithSampleData() async {
    if (!mounted) return;

    final dataService = Provider.of<IDataService>(context, listen: false);
    final imageDataService = Provider.of<IImageDataService?>(
      context,
      listen: false,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'Reset ALL data to sample set? This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          TextButton(
            child: const Text(
              'Reset All Data',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database... Please wait.')),
      );

      final populator = SampleDataPopulator(
        dataService: dataService,
        imageDataService: imageDataService,
      );

      try {
        await populator.populate();
        _logger.info("Sample data population successful from LocationsPage.");
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database has been reset with sample data.'),
            ),
          );
          // Trigger a refresh of the locations list
          _handleRefresh();
        }
      } catch (e, s) {
        _logger.severe(
          "Error during sample data population from LocationsPage: $e",
          e,
          s,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting database: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Widget? _buildDeveloperDrawer(BuildContext context) {
    if (!kDebugMode) {
      return null;
    }
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Text(
              'Developer Options',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Reset DB with Sample Data'),
            onTap: () async {
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Close drawer first
              }
              await _resetDatabaseWithSampleData();
            },
          ),
        ],
      ),
    );
  }
  // --- End of Developer Tools Logic ---

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(key: Key("locations_waiting_spinner")),
    );
  }

  Widget _buildErrorState(AsyncSnapshot<List<Location>> snapshot) {
    _logger.severe(
      "Error in StreamBuilder: ${snapshot.error}",
      snapshot.error,
      snapshot.stackTrace,
    );
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading locations: ${snapshot.error}'),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              _logger.info("Retrying stream subscription.");
              if (mounted) {
                // To retry, we need to ensure the stream is re-listened to or re-created.
                // Calling _handleRefresh might be a good option if it re-fetches
                // and the stream updates. Or re-assign the stream.
                _handleRefresh(); // Or:
                // setState(() {
                //   _locationsStream = _dataService.getLocationsStream();
                // });
              }
            },
            child: const Text('Retry Stream'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    _logger.info("StreamBuilder: No locations found or data is null/empty.");
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No locations found. Tap + to add one or pull down to refresh.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Add First Location'),
                      onPressed: _addNewLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationImage(
    Location location,
    IImageDataService? imageDataService,
  ) {
    _logger.fine(
      "Building image for location ${location.id}. ImageDataService is ${imageDataService == null ? 'NULL' : 'AVAILABLE'}. Image GUIDs: ${location.imageGuids}",
    );

    if (imageDataService != null &&
        location.imageGuids != null &&
        location.imageGuids!.isNotEmpty) {
      final firstImageGuidWithExt = location.imageGuids!.firstWhere(
        (guid) => guid.isNotEmpty,
        orElse: () => '',
      );

      if (firstImageGuidWithExt.isNotEmpty) {
        return imageDataService.getUserImage(
          firstImageGuidWithExt,
          width: 80.0,
          height: 80.0,
          fit: BoxFit.cover,
        );
      }
    }
    // Fallback placeholder
    return Image.asset(
      'assets/images/location_placeholder.jpg',
      height: 80.0,
      width: 80.0,
      fit: BoxFit.cover,
      key: Key('placeholder_image_${location.id}_fallback'),
    );
  }

  Widget _buildLocationCard(
    Location location,
    IImageDataService? imageDataService,
  ) {
    _logger.fine(
      "Building card for location ${location.name}, imageGuids: ${location.imageGuids}",
    );
    return Card(
      key: ValueKey('location_card_${location.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _buildLocationImage(location, imageDataService),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (location.description != null &&
                      location.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        location.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (location.address != null && location.address!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Address: ${location.address!}",
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        key: Key('view_location_${location.id}'),
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('View'),
                        onPressed: () => _viewLocationContents(location),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      OutlinedButton.icon(
                        key: Key('edit_location_${location.id}'),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit'),
                        onPressed: () => _editLocationInfo(location),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
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

  Widget _buildLocationsList(
    List<Location> locations,
    IImageDataService? imageDataService,
  ) {
    return ListView.builder(
      key: const Key('locations_list_view'),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return _buildLocationCard(location, imageDataService);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("LocationsPage building its content.");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        leading: kDebugMode
            ? Builder(
                builder: (BuildContext appBarContext) {
                  return IconButton(
                    icon: const Icon(Icons.menu),
                    tooltip: 'Developer Options',
                    onPressed: () {
                      Scaffold.of(appBarContext).openDrawer();
                    },
                  );
                },
              )
            : null,
      ),
      drawer: _buildDeveloperDrawer(context),
      body: RefreshIndicator(
        key: const Key("locations_refresh_indicator"),
        onRefresh: _handleRefresh,
        child: Consumer<IImageDataService?>(
          builder: (context, imageDataServiceFromConsumer, child) {
            _logger.info(
              "LocationsPage Consumer<IImageDataService>: Service is ${imageDataServiceFromConsumer == null ? 'NULL' : 'AVAILABLE'}",
            );

            return StreamBuilder<List<Location>>(
              stream: _locationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !(snapshot.hasData || snapshot.hasError)) {
                  _logger.fine(
                    "StreamBuilder: ConnectionState.waiting (initial load likely)",
                  );
                  return _buildLoadingIndicator();
                }
                if (snapshot.hasError) {
                  _logger.warning("StreamBuilder: Error: ${snapshot.error}");
                  return _buildErrorState(snapshot);
                }
                if (!snapshot.hasData ||
                    snapshot.data == null ||
                    snapshot.data!.isEmpty) {
                  _logger.info("StreamBuilder: No data or empty list.");
                  return _buildEmptyState();
                }

                _logger.fine(
                  "StreamBuilder: HasData with ${snapshot.data!.length} items.",
                );
                return _buildLocationsList(
                  snapshot.data!,
                  imageDataServiceFromConsumer,
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: const ValueKey('add_location_fab'),
        heroTag: 'locationsPageFAB',
        onPressed: _addNewLocation, // Use the existing method
        tooltip: 'Add Location',
        child: const Icon(Icons.add_location_alt_outlined),
      ),
    );
  }
}
