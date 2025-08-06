// lib/pages/edit_location_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../viewmodels/edit_location_view_model.dart';
import '../models/location_model.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../widgets/image_manager_input.dart';

final Logger _logger = Logger('EditLocationPage');

class EditLocationPage extends StatelessWidget {
  final Location? initialLocation;
  final EditLocationViewModel? viewModelOverride;

  const EditLocationPage({
    super.key,
    this.initialLocation,
    this.viewModelOverride,
  });

  // --- Private Helper Method for Save Logic ---
  Future<void> _handleSaveAttempt(
    BuildContext context,
    EditLocationViewModel viewModel,
  ) async {
    final bool isFormValid =
        viewModel.formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      _logger.info('Form is invalid. Save attempt aborted.');
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final bool isNewLoc = viewModel.isNewLocation;

    _logger.info('Attempting to save location. New location: $isNewLoc');
    bool success = await viewModel.saveLocation();
    _logger.info('Save attempt completed. Success: $success');

    if (!context.mounted) {
      _logger.warning(
        'Context not mounted after save attempt. Aborting UI updates.',
      );
      return;
    }

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isNewLoc ? 'Location added.' : 'Location updated.'),
        ),
      );
      if (navigator.canPop()) {
        _logger.info("Popping Edit Location Page after successful save.");
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
          decoration: InputDecoration(
            labelText: 'Address',
            hintText: 'e.g., 123 Main St, Anytown',
            border: const OutlineInputBorder(),
            suffixIcon: viewModel.deviceHasLocationService
                ? (viewModel.isGettingLocation
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.0),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location),
                          tooltip: 'Get Current Address',
                          onPressed: viewModel.getCurrentAddress,
                        ))
                : null,
          ),
          maxLines: 2,
        ),
        if (!viewModel.deviceHasLocationService)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Device location service is unavailable or permission denied. Please check settings.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  // Widget _buildImageSection(
  //   BuildContext context,
  //   EditLocationViewModel viewModel,
  // ) {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text('Images', style: Theme.of(context).textTheme.titleMedium),
  //       const SizedBox(height: 8.0),
  //       viewModel.currentImages.isEmpty
  //           ? const Center(
  //               child: Padding(
  //                 padding: EdgeInsets.symmetric(vertical: 16.0),
  //                 child: Text('No images yet. Add one!'),
  //               ),
  //             )
  //           : SizedBox(
  //               height: 120.0,
  //               child: ListView.builder(
  //                 scrollDirection: Axis.horizontal,
  //                 itemCount: viewModel.currentImages.length,
  //                 itemBuilder: (context, index) {
  //                   final imageId = viewModel.currentImages[index];
  //                   return Padding(
  //                     padding: const EdgeInsets.only(right: 8.0),
  //                     child: Stack(
  //                       children: [
  //                         Container(
  //                           width: 100.0,
  //                           height: 100.0,
  //                           decoration: BoxDecoration(
  //                             border: Border.all(color: Colors.grey),
  //                             borderRadius: BorderRadius.circular(8.0),
  //                           ),
  //                           child: ClipRRect(
  //                             borderRadius: BorderRadius.circular(7.0),
  //                             child: viewModel.getImageThumbnailWidget(
  //                               imageId,
  //                               width: 100.0,
  //                               height: 100.0,
  //                               fit: BoxFit.cover,
  //                             ),
  //                           ),
  //                         ),
  //                         Padding(
  //                           padding: const EdgeInsets.all(2.0),
  //                           child: Material(
  //                             color: Colors.transparent,
  //                             shape: const CircleBorder(),
  //                             child: InkWell(
  //                               onTap: () => viewModel.removeImage(index),
  //                               customBorder: const CircleBorder(),
  //                               child: Container(
  //                                 padding: const EdgeInsets.all(2.0),
  //                                 decoration: const BoxDecoration(
  //                                   color: Color.fromARGB(128, 0, 0, 0),
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                                 child: const Icon(
  //                                   Icons.close,
  //                                   color: Colors.white,
  //                                   size: 18,
  //                                 ),
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                   );
  //                 },
  //               ),
  //             ),
  //       const SizedBox(height: 12.0),
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.start,
  //         children: [
  //           IconButton(
  //             icon: const Icon(Icons.camera_alt_outlined),
  //             tooltip: 'Add Image from Camera',
  //             onPressed: viewModel.pickImageFromCamera,
  //             iconSize: 28,
  //           ),
  //           const SizedBox(width: 16),
  //           IconButton(
  //             icon: const Icon(Icons.photo_library_outlined),
  //             tooltip: 'Add Image from Gallery',
  //             onPressed: viewModel.pickImageFromGallery,
  //             iconSize: 28,
  //           ),
  //         ],
  //       ),
  //     ],
  //   );
  // }

  Widget _buildActionButtons(
    BuildContext context,
    EditLocationViewModel viewModel,
  ) {
    return ElevatedButton.icon(
      key: ValueKey(
        viewModel.isNewLocation ? 'addLocationButton' : 'saveLocationButton',
      ),
      icon: viewModel.isSaving
          ? Container() // Handled by isLoading in ImageManagerInput or global page lock
          : (viewModel.isNewLocation
                ? const Icon(Icons.add_circle_outline)
                : const Icon(Icons.save_outlined)),
      label: Text(viewModel.isNewLocation ? 'Add Location' : 'Save Changes'),
      onPressed: viewModel.isSaving
          ? null
          : () async {
              await _handleSaveAttempt(context, viewModel);
            },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        backgroundColor: viewModel.isSaving ? Colors.grey : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EditLocationViewModel effectiveViewModel =
        viewModelOverride ??
        () {
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
          return EditLocationViewModel(
            dataService: dataService,
            imageDataService: imageDataService,
            locationService: locationService,
            imagePickerService: imagePickerService,
            tempFileService: tempFileService,
            initialLocation: initialLocation,
          );
        }();

    return ChangeNotifierProvider<EditLocationViewModel>.value(
      value: effectiveViewModel,
      child: Consumer<EditLocationViewModel>(
        builder: (context, viewModel, child) {
          final appBarTitle = viewModel.isNewLocation
              ? 'Add New Location'
              : 'Edit Location';

          return Scaffold(
            appBar: AppBar(
              title: Text(appBarTitle),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  _logger.info(
                    "AppBar back button tapped. Calling viewModel.handleDiscardOrPop.",
                  );
                  await viewModel.handleDiscardOrPop(context);
                },
              ),
            ),
            body: PopScope(
              canPop:
                  !viewModel.isSaving &&
                  !viewModel.isPickingImage &&
                  !viewModel.hasUnsavedChanges,
              onPopInvokedWithResult: (bool didPop, Object? result) async {
                _logger.info(
                  "PopScope.onPopInvoked: didPop: $didPop, "
                  "isSaving: ${viewModel.isSaving}, "
                  "isPickingImage: ${viewModel.isPickingImage}, "
                  "hasUnsaved: ${viewModel.hasUnsavedChanges}",
                );
                if (didPop) return;

                await viewModel.handleDiscardOrPop(context);
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: viewModel.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildFormFields(context, viewModel),
                      const SizedBox(height: 24.0),
                      ImageManagerInput(
                        currentImages: viewModel.currentImages,
                        imageThumbnailBuilder:
                            (
                              imageId, {
                              required width,
                              required height,
                              required fit,
                            }) {
                              // This lambda directly calls the ViewModel's method
                              return viewModel.getImageThumbnailWidget(
                                imageId,
                                width: width,
                                height: height,
                                fit: fit,
                              );
                            },
                        onAddImageFromCamera: viewModel.pickImageFromCamera,
                        onAddImageFromGallery: viewModel.pickImageFromGallery,
                        onRemoveImage: viewModel.removeImage,
                        isLoading: viewModel.isPickingImage,
                        title: 'Location Images',
                      ),
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
