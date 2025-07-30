// lib/locations_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import 'edit_location_page.dart';

final Logger _logger = Logger('LocationsPage');

class LocationsPage extends StatefulWidget {
  final Function(Location) onViewLocationContents;

  const LocationsPage({super.key, required this.onViewLocationContents});

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

  Future<void> _navigateAndAwaitChanges(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );

    _logger.info(
      "Returned from a page navigation. Stream should handle UI updates.",
    );
  }

  // --- Actions ---
  void _editLocationInfo(Location location) {
    _navigateAndAwaitChanges(EditLocationPage(initialLocation: location));
  }

  void _addNewLocation() {
    _navigateAndAwaitChanges(const EditLocationPage());
  }

  void _viewLocationContents(Location location) {
    widget.onViewLocationContents(location);
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(key: Key("locations_waiting_spinner")),
    );
  }

  Widget _buildErrorState(AsyncSnapshot<List<Location>> snapshot) {
    _logger.severe(
      "Error in FutureBuilder: ${snapshot.error}",
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
    _logger.info("FutureBuilder: No locations found or data is null/empty.");
    // LayoutBuilder ensures SingleChildScrollView has constraints to work correctly when empty
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics:
              const AlwaysScrollableScrollPhysics(), // Important for empty list refresh
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No locations found. Tap + to add one or pull down to refresh.',
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
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final location = locations[index];
        return _buildLocationCard(location, imageDataService);
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 16.0,
      right: 16.0,
      child: FloatingActionButton(
        onPressed: _addNewLocation,
        tooltip: 'Add Location',
        child: const Icon(Icons.add),
      ),
    );
  }

  // --- Main Build Method (Refactored) ---
  @override
  Widget build(BuildContext context) {
    // final currentImageDataService = Provider.of<IImageDataService?>(context, listen: false);
    // _logger.info("LocationsPage build: currentImageDataService is ${currentImageDataService == null ? 'NULL' : 'AVAILABLE'}");

    // if (currentImageDataService == null) {
    //   _logger.warning("ImageDataService is null in LocationsPage build. FutureProvider might still be loading or service not available.");
    // }

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            key: const Key("locations_refresh_indicator"),
            onRefresh: _handleRefresh,
            child: Consumer<IImageDataService?>(
              builder: (context, imageDataServiceFromConsumer, child) {
                _logger.info(
                  "LocationsPage Consumer<IImageDataService>: Service is ${imageDataServiceFromConsumer == null ? 'NULL' : 'AVAILABLE'}",
                );

                if (imageDataServiceFromConsumer == null) {
                  // _isAttemptingToLoadImages checks if locations have imageGuids
                  _logger.info(
                    "ImageDataService is null, but images are expected. Showing main loading indicator.",
                  );
                  // Show a loading indicator for the whole list, or a modified empty/loading state for list items
                  return _buildLoadingIndicator(); // Or a more specific "loading image service" indicator
                }

                return StreamBuilder<List<Location>>(
                  stream: _locationsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      _logger.fine("StreamBuilder snapshot: waiting");
                      return _buildLoadingIndicator();
                    }
                    if (snapshot.hasError) {
                      _logger.warning(
                        "StreamBuilder snapshot: hasError: ${snapshot.error}",
                      );
                      return _buildErrorState(snapshot);
                    }
                    if (!snapshot.hasData ||
                        snapshot.data == null ||
                        snapshot.data!.isEmpty) {
                      _logger.info(
                        "StreamBuilder snapshot: no data or empty list.",
                      );
                      return _buildEmptyState();
                    }
                    _logger.fine(
                      "StreamBuilder snapshot: hasData with ${snapshot.data!.length} items.",
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
          _buildFloatingActionButton(),
        ],
      ),
    );
  }
}
