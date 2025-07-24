// lib/edit_location_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:logging/logging.dart';

import 'models/location_model.dart';
import 'services/database_service.dart';

final Logger _logger = Logger('EditLocationPage');

class EditLocationPage extends StatefulWidget {
  final Location? initialLocation; // Null if adding a new location

  const EditLocationPage({super.key, this.initialLocation});

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;

  final ImagePicker _picker = ImagePicker();
  List<String> _currentImagePaths = [];

  bool _isNewLocation = true;
  bool _isGettingLocation = false;
  bool _deviceHasLocationService = true; // Assume true initially

  @override
  void initState() {
    super.initState();
    _isNewLocation = widget.initialLocation == null;

    _nameController = TextEditingController(
      text: widget.initialLocation?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialLocation?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.initialLocation?.address ?? '',
    );

    if (widget.initialLocation != null) {
      _currentImagePaths = List.from(widget.initialLocation!.imagePaths);
    }

    _checkLocationServiceStatus();
  }

  Future<void> _checkLocationServiceStatus() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _deviceHasLocationService = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _deviceHasLocationService =
              false; // Treat as no service if permanently denied
        });
      }
      return;
    }
    // If denied (but not forever), we can ask when the button is pressed.
    // For now, assume service is available if not disabled or permanently denied.
    if (mounted) {
      setState(() {
        _deviceHasLocationService = true;
      });
    }
  }

  Future<void> _getCurrentAddress() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
            setState(() {
              _isGettingLocation = false;
              _deviceHasLocationService =
                  permission != LocationPermission.deniedForever;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Please enable it in settings.',
              ),
            ),
          );
          setState(() {
            _isGettingLocation = false;
            _deviceHasLocationService = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<geocoding.Placemark> placemarks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty && mounted) {
        final placemark = placemarks.first;
        final street = placemark.street ?? '';
        final subLocality = placemark.subLocality ?? '';
        final locality = placemark.locality ?? '';
        final postalCode = placemark.postalCode ?? '';
        final country = placemark.country ?? '';

        // Construct a readable address - customize as needed
        String formattedAddress = [
          street,
          subLocality,
          locality,
          postalCode,
          country,
        ].where((s) => s.isNotEmpty).join(', ');

        _addressController.text = formattedAddress;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not determine address from location.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
        _checkLocationServiceStatus(); // Re-check status in case it changed
      }
      _logger.severe("Error getting current address: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    // 1. Check Camera Permission
    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) {
      cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission denied.')),
          );
        }
        return;
      }
    }

    // 2. Pick Image
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024, // Optional: Resize to save space
        maxHeight: 1024,
        imageQuality: 85, // Optional: Compress
      );

      if (pickedFile != null && mounted) {
        // 3. Copy image to app's directory to ensure it persists
        final File imageFile = File(pickedFile.path);
        final String appDocPath =
            (await getApplicationDocumentsDirectory()).path;
        final String fileName = p.basename(imageFile.path);
        final String localPath = p.join(
          appDocPath,
          'location_images',
          fileName,
        );

        // Ensure the directory exists
        final Directory localImagesDir = Directory(
          p.join(appDocPath, 'location_images'),
        );
        if (!await localImagesDir.exists()) {
          await localImagesDir.create(recursive: true);
        }

        await imageFile.copy(localPath);

        setState(() {
          _currentImagePaths.add(localPath); // Add the *persistent* path
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
      _logger.severe("Error picking image: $e");
    }
  }

  Future<void> _removeImage(int index) async {
    if (!mounted) return;
    final String pathToRemove = _currentImagePaths[index];
    setState(() {
      _currentImagePaths.removeAt(index);
    });

    if (!pathToRemove.startsWith('assets/')) {
      try {
        final file = File(pathToRemove);
        await file.delete();
        _logger.info("File $pathToRemove deleted successfully.");
      } catch (e) {
        _logger.severe("Error deleting file $pathToRemove: $e");
        // Optional: Handle the error more specifically.
        // For example, re-add the path and show a message:
        // if (mounted) {
        //   setState(() {
        //     _currentImagePaths.insert(index, pathToRemove);
        //   });
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(content: Text('Failed to delete image file: $pathToRemove. It has been re-added.')),
        //   );
        // }
        // Or simply log and move on.
      }
    }
    if (mounted) {
      // Check mounted again if any async operations happened before this
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image removed.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _saveLocation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Important for onSaved callbacks if used

      final String name = _nameController.text.trim();
      final String? description = _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null;
      final String? address = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null;

      if (_isNewLocation) {
        final newId = 'loc_${DateTime.now().millisecondsSinceEpoch}';
        final newLocation = Location(
          id: newId,
          name: name,
          description: description,
          address: address,
          imagePaths: List.from(_currentImagePaths),
        );
        await DatabaseService.locationsBox.add(newLocation);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${newLocation.name} added.')));
        }
      } else {
        // Editing existing location
        final existingLocation = widget.initialLocation!;
        existingLocation.name = name;
        existingLocation.description = description;
        existingLocation.address = address;
        existingLocation.imagePaths = List.from(_currentImagePaths);
        await existingLocation.save(); // Hive saves changes to existing object
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${existingLocation.name} updated.')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String path) {
    // Define a consistent placeholder for errors within this page too
    const Widget errorPlaceholder = Center(
      child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
    );

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logger.severe(
            "EDIT_PAGE: Error loading ASSET '$path'. Error: $error",
          );
          return errorPlaceholder;
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logger.severe(
            "EDIT_PAGE: Error loading FILE '$path'. Error: $error",
          );
          return errorPlaceholder;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNewLocation ? 'Add New Location' : 'Edit Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveLocation,
            tooltip: 'Save Location',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name*',
                  hintText: 'e.g., Home, Office',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'e.g., 123 Main St, Anytown',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8.0),
              if (_deviceHasLocationService)
                _isGettingLocation
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Get Current Address'),
                        onPressed: _getCurrentAddress,
                      ),
              if (!_deviceHasLocationService)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Device location service is unavailable or permission denied.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Text('Images', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8.0),
              _currentImagePaths.isEmpty
                  ? const Text(
                      'No images yet. Add one!',
                      textAlign: TextAlign.center,
                    )
                  : SizedBox(
                      height: 120.0, // Adjust height as needed
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _currentImagePaths.length,
                        itemBuilder: (context, index) {
                          final imagePath = _currentImagePaths[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              children: [
                                Container(
                                  width: 100.0, // Adjust width
                                  height: 100.0, // Adjust height
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7.0),
                                    child: _buildImageWidget(imagePath),
                                  ),
                                ),
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle,
                                      color: Colors.redAccent,
                                    ),
                                    iconSize: 24,
                                    tooltip: 'Remove Image',
                                    onPressed: () => _removeImage(index),
                                    padding: EdgeInsets.zero,
                                    constraints:
                                        const BoxConstraints(), // Make it tight
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 12.0),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add Image from Camera'),
                onPressed: _pickImageFromCamera,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveLocation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: Text(_isNewLocation ? 'Add Location' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
