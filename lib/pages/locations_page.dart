// lib/locations_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../routing/app_routes.dart';

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
      setState(() {});
      await _dataService.getAllLocations();
    }
    _logger.info("RefreshIndicator completed.");
  }

  // Future<void> _navigateAndAwaitChanges(Widget page) async {
  //   await Navigator.push(
  //     context,
  //     MaterialPageRoute(builder: (context) => page),
  //   );
  //
  //   _logger.info(
  //     "Returned from a page navigation. Stream should handle UI updates.",
  //   );
  // }

  // --- Actions ---
  void _editLocationInfo(Location location) {
    _logger.info("Navigating to edit location: ${location.name}");
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.editLocation, arguments: location);
  }

  void _addNewLocation() {
    _logger.info("Navigating to add new location page.");
    Navigator.of(context).pushNamed(AppRoutes.addLocation);
  }

  void _viewLocationContents(Location location) {
    _logger.info("Navigating to view contents for location: ${location.name}");
    Navigator.of(context).pushNamed(AppRoutes.rooms, arguments: location);
  }

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
                setState(() {
                  _locationsStream = _dataService.getLocationsStream();
                });
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
      'assets/images/location_placeholder.png',
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

  // --- Main Build Method (Refactored) ---
  @override
  Widget build(BuildContext context) {
    _logger.info("LocationsPage building its content.");

    return RefreshIndicator(
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
                // Show loading only if it's the initial wait and no data/error yet.
                // If it's ConnectionState.waiting but hasData, it's likely a stream update.
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
              // Pass the potentially null imageDataServiceFromConsumer.
              // _buildLocationsList and _buildLocationCard will handle it.
              return _buildLocationsList(
                snapshot.data!,
                imageDataServiceFromConsumer,
              );
            },
          );
        },
      ),
    );
  }
}
