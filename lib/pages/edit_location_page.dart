// lib/edit_location_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

// ViewModel and Services
import '../viewmodels/edit_location_view_model.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../core/image_identifier.dart';

final Logger _logger = Logger('EditLocationPage');

class EditLocationPage extends StatelessWidget {
  final Location? initialLocation; // Null if adding a new location

  const EditLocationPage({super.key, this.initialLocation});

  // Helper for individual image display (already well-defined)
  Widget _buildIndividualImageThumbnail(
    BuildContext context,
    ImageIdentifier identifier,
    IImageDataService? imageDataService,
  ) {
    if (identifier is GuidIdentifier) {
      if (imageDataService == null) {
        _logger.warning(
          "IImageDataService is null, cannot display persisted image for GUID: ${identifier.guid}",
        );
        return const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 50),
        );
      }
      return imageDataService.getUserImage(
        identifier.guid,
        width: 100.0,
        height: 100.0,
        fit: BoxFit.cover,
      );
    } else if (identifier is TempFileIdentifier) {
      return Image.file(
        identifier.file,
        width: 100.0,
        height: 100.0,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logger.severe(
            "Error loading TEMP image ${identifier.file.path}: $error",
            error,
            stackTrace,
          );
          return const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
          );
        },
      );
    }
    _logger.warning(
      "Unknown ImageIdentifier type encountered in _buildIndividualImageThumbnail",
    );
    return const SizedBox.shrink();
  }

  // --- Private Builder Methods for UI Sections ---

  AppBar _buildAppBar(BuildContext context, EditLocationViewModel viewModel) {
    return AppBar(
      title: Text(
        viewModel.isNewLocation ? 'Add New Location' : 'Edit Location',
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await viewModel.handleDiscardOrPop();
          if (!context.mounted) return;
          if (Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: viewModel.isSaving
              ? null
              : () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final bool isNewLoc = viewModel.isNewLocation;

                  bool success = await viewModel.saveLocation();

                  if (!context.mounted) return;

                  if (success) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          isNewLoc ? 'Location added.' : 'Location updated.',
                        ),
                      ),
                    );
                    if (navigator.canPop()) {
                      navigator.pop();
                    }
                  } else {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Failed to save location. Check details and try again.',
                        ),
                      ),
                    );
                  }
                },
          tooltip: 'Save Location',
        ),
      ],
    );
  }

  Widget _buildFormFields(
    BuildContext context,
    EditLocationViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: viewModel.nameController,
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
          controller: viewModel.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: viewModel.addressController,
          decoration: const InputDecoration(
            labelText: 'Address',
            hintText: 'e.g., 123 Main St, Anytown',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildLocationServicesSection(
    BuildContext context,
    EditLocationViewModel viewModel,
  ) {
    if (viewModel.deviceHasLocationService) {
      return viewModel.isGettingLocation
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          : OutlinedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Get Current Address'),
              onPressed: viewModel.getCurrentAddress,
            );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'Device location service is unavailable or permission denied. Please check settings.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildImageSection(
    BuildContext context,
    EditLocationViewModel viewModel,
    IImageDataService? imageDataService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        viewModel.currentImages.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No images yet. Add one!'),
                ),
              )
            : SizedBox(
                height: 120.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.currentImages.length,
                  itemBuilder: (context, index) {
                    final imageId = viewModel.currentImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        children: [
                          Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: _buildIndividualImageThumbnail(
                                context,
                                imageId,
                                imageDataService,
                              ),
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
                              onPressed: () => viewModel.removeImage(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
          onPressed: viewModel.pickImageFromCamera,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    EditLocationViewModel viewModel,
  ) {
    return ElevatedButton(
      onPressed: viewModel.isSaving
          ? null
          : () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final bool isNewLoc = viewModel.isNewLocation;

              bool success = await viewModel.saveLocation();

              if (!context.mounted) return;

              if (success) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isNewLoc ? 'Location added.' : 'Location updated.',
                    ),
                  ),
                );
                if (navigator.canPop()) {
                  _logger.info("Popping Edit Location Page");
                  navigator.pop();
                }
              } else {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Failed to save. Please check details and try again.',
                    ),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        backgroundColor: viewModel.isSaving ? Colors.grey : null,
      ),
      child: viewModel.isSaving
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(viewModel.isNewLocation ? 'Add Location' : 'Save Changes'),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    final dataService = Provider.of<IDataService>(context, listen: false);
    final imageDataService = Provider.of<IImageDataService?>(
      context,
      listen: false,
    );
    final locationService = Provider.of<ILocationService>(
      context,
      listen: false,
    );
    final imagePickerService = Provider.of<IImagePickerService>(
      context,
      listen: false,
    );
    final tempFileService = Provider.of<ITemporaryFileService>(
      context,
      listen: false,
    );

    return ChangeNotifierProvider<EditLocationViewModel>(
      create: (_) => EditLocationViewModel(
        dataService: dataService,
        imageDataService: imageDataService,
        locationService: locationService,
        imagePickerService: imagePickerService,
        tempFileService: tempFileService,
        initialLocation: initialLocation,
      ),
      child: Consumer<EditLocationViewModel>(
        builder: (context, viewModel, child) {
          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              if (didPop) {
                _logger.finer(
                  "PopScope (onPopInvokedWithResult): Pop invoked for EditLocationPage. Cleaning up. Result: $result",
                );
                await viewModel.handleDiscardOrPop();
              }
            },
            child: Scaffold(
              appBar: _buildAppBar(context, viewModel),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: viewModel.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildFormFields(context, viewModel),
                      const SizedBox(height: 8.0),
                      _buildLocationServicesSection(context, viewModel),
                      const SizedBox(height: 16.0),
                      _buildImageSection(
                        context,
                        viewModel,
                        imageDataService,
                      ), // Pass imageDataService
                      const SizedBox(height: 24.0),
                      _buildActionButtons(context, viewModel),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
