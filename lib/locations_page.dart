// lib/locations_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import for ValueListenableBuilder
import 'package:logging/logging.dart';
import 'models/location_model.dart'; // Import your model
import 'services/database_service.dart';
import 'edit_location_page.dart';

final Logger _logger = Logger('LocationsPage');

// Placeholder for your actual image assets or network image handling
Widget _getLocationImage(List<String> imagePaths) {
  const String placeholderAsset = 'assets/images/location_placeholder.png';
  const double imageSize = 80.0;

  if (imagePaths.isNotEmpty && imagePaths.first.isNotEmpty) {
    final path = imagePaths.first;

    // Check if the path looks like an asset path
    if (path.startsWith('assets/')) {
      try {
        return Image.asset(
          // Use Image.asset for bundled application assets
          path,
          height: imageSize,
          width: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _logger.severe(
              "Error loading ASSET '$path'. Falling back to placeholder. Error: $error",
            );
            return Image.asset(
              // Fallback to placeholder asset
              placeholderAsset,
              height: imageSize,
              width: imageSize,
              fit: BoxFit.cover,
            );
          },
        );
      } catch (e) {
        _logger.severe("Exception trying to load ASSET '$path': $e");
        // Fall through to default placeholder
      }
    } else {
      // Assuming paths stored are full paths to files in app directory
      try {
        return Image.file(
          // Changed from Image.asset
          File(path),
          height: imageSize,
          width: imageSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            _logger.severe(
              "Error loading file image '$path'. Falling back. Error: $error",
            );
            return Image.asset(
              placeholderAsset,
              height: imageSize,
              width: imageSize,
              fit: BoxFit.cover,
            );
          },
        );
      } catch (e) {
        _logger.severe("Error creating File object for image '$path': $e");
        // fall through to default placeholder
      }
    }
  }
  // Default placeholder if imagePaths is empty or if any error occurred above
  return Image.asset(
    placeholderAsset,
    height: imageSize,
    width: imageSize,
    fit: BoxFit.cover,
  );
}

class LocationsPage extends StatefulWidget {
  final Function(Location) onViewLocationContents;

  const LocationsPage({super.key, required this.onViewLocationContents});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  @override
  void initState() {
    super.initState();
  }

  // --- Actions ---
  void _viewLocationContents(Location location) {
    widget.onViewLocationContents(location);
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => RoomsPage(
    //       locationName: location.name,
    //       locationId: location.id,
    //     ), // Pass ID too
    //   ),
    // );
  }

  void _editLocationInfo(Location location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationPage(initialLocation: location),
      ),
    ).then((_) {
      // Optional: Refresh list or state if needed after edit page pops,
      // though ValueListenableBuilder should handle it if Hive object changed.
      // setState(() {}); // Usually not needed if HiveObject.save() was called.
    });
  }

  void _addNewLocation() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const EditLocationPage(), // Pass no initialLocation for new
      ),
    ).then((_) {
      // Optional: Refresh list or state if needed after edit page pops.
      // setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      // Use Stack if you need a FAB that overlaps the ListView
      children: [
        ValueListenableBuilder<Box<Location>>(
          valueListenable: DatabaseService.locationsBox.listenable(),
          builder: (context, box, _) {
            if (box.values.isEmpty) {
              return const Center(
                child: Text(
                  'No locations found. Tap + to add one or use Developer Options to reset data.',
                ),
              );
            }
            final locations = box.values.toList().cast<Location>();
            return ListView.builder(
              itemCount: locations.length,
              itemBuilder: (context, index) {
                // ... your Card and Row structure ...
                final location = locations[index];
                return Card(
                  // Using Card for better visual separation
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        _getLocationImage(location.imagePaths),
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
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (location.address != null &&
                                  location.address!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Address: ${location.address!}", // Simple display
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .start, // Align buttons to start
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(
                                      Icons.inventory_2_outlined,
                                    ),
                                    label: const Text('View'),
                                    onPressed: () =>
                                        _viewLocationContents(location),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                    onPressed: () =>
                                        _editLocationInfo(location),
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
              },
            );
          },
        ),
        Positioned(
          // For the FAB
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: _addNewLocation,
            tooltip: 'Add Location',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
