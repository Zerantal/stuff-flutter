import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../models/room_model.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../viewmodels/edit_room_view_model.dart';

final Logger _logger = Logger('EditRoomPage');

class EditRoomPage extends StatelessWidget {
  final Location parentLocation;
  final Room? initialRoom; // Null if adding a new room
  final EditRoomViewModel? viewModelOverride; // For testing

  const EditRoomPage({
    super.key,
    required this.parentLocation,
    this.initialRoom,
    this.viewModelOverride,
  });

  Future<bool> _onWillPop(BuildContext context, EditRoomViewModel viewModel) async {
    _logger.finer("Pop attempt on EditRoomPage. Unsaved changes: ${viewModel.hasUnsavedChanges}");
    // if (viewModel.hasUnsavedChanges) {
    //   final confirm = await showConfirmationDialog(
    //     context: context,
    //     title: 'Discard Changes?',
    //     content:
    //         'You have unsaved changes. Are you sure you want to discard them and go back?',
    //     confirmText: 'Discard',
    //   );
    //   if (confirm == true) {
    //     _logger.info("User confirmed discarding changes.");
    //     // ViewModel's PopScope onPopInvokedWithResult should handle cleanup if didPop is true
    //     return true; // Allow pop
    //   }
    //   _logger.info("User cancelled discarding changes.");
    //   return false; // Prevent pop
    // }
    return true; // Allow pop if no unsaved changes
  }

  Future<void> _handleSaveAttempt(BuildContext context, EditRoomViewModel viewModel) async {
    final bool isFormValid = viewModel.formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      _logger.info('Form is invalid. Save attempt aborted.');
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final bool isNew = viewModel.isNewRoom;

    _logger.info('Attempting to save room. New room: $isNew');
    bool success = await viewModel.saveRoom();
    _logger.info('Save attempt completed. Success: $success');

    if (!context.mounted) {
      _logger.warning('Context not mounted after save attempt. Aborting UI updates.');
      return;
    }

    if (success) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(isNew ? 'Room added.' : 'Room updated.')),
      );
      if (navigator.canPop()) {
        _logger.info("Popping Edit Room Page after successful save.");
        navigator.pop();
      }
    } else {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Failed to save room. Check details and try again.')),
      );
    }
  }

  Widget _buildFormFields(BuildContext context, EditRoomViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: viewModel.nameController,
          decoration: const InputDecoration(
            labelText: 'Room Name*',
            hintText: 'e.g., Kitchen, Master Bedroom',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a room name.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
        TextFormField(
          controller: viewModel.descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'e.g., Contains workbench and tools',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  // --- COPIED AND ADAPTED FROM EDIT_LOCATION_PAGE ---
  Widget _buildImageSection(
    BuildContext context,
    EditRoomViewModel viewModel, // Changed to EditRoomViewModel
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Images', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        viewModel.currentImages.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child:
                      viewModel
                          .isSaving // Prevent adding images while saving
                      ? const Text('Saving, please wait...')
                      : const Text('No images yet. Add one!'),
                ),
              )
            : SizedBox(
                height: 120.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.currentImages.length,
                  itemBuilder: (context, index) {
                    final imageIdentifier = viewModel.currentImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        alignment: Alignment.topLeft,
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
                              child: viewModel.getImageThumbnailWidget(
                                imageIdentifier, // Pass identifier (GUID)
                                width: 100.0,
                                height: 100.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Delete button
                          if (!viewModel.isSaving) // Don't allow removal during save
                            Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: () => viewModel.removeImage(index),
                                customBorder: const CircleBorder(),
                                child: Container(
                                  margin: const EdgeInsets.all(2.0),
                                  padding: const EdgeInsets.all(2.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(128),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 12.0),
        // Add image buttons
        if (!viewModel.isSaving) // Don't allow adding during save
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Add Image from Camera',
                onPressed: viewModel.pickImageFromCamera,
                iconSize: 28,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.photo_library_outlined),
                tooltip: 'Add Image from Gallery',
                onPressed: viewModel.pickImageFromGallery,
                iconSize: 28,
              ),
            ],
          ),
      ],
    );
  }
  // --- END OF COPIED SECTION ---

  Widget _buildActionButtons(BuildContext context, EditRoomViewModel viewModel) {
    return ElevatedButton.icon(
      key: ValueKey(viewModel.isNewRoom ? 'addRoomButton' : 'saveRoomButton'),
      icon: viewModel.isSaving
          ? Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2.0),
              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            )
          : (viewModel.isNewRoom
                ? const Icon(Icons.add_circle_outline)
                : const Icon(Icons.save_outlined)),
      label: Text(viewModel.isNewRoom ? 'Add Room' : 'Save Changes'),
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
    final EditRoomViewModel effectiveViewModel =
        viewModelOverride ??
        () {
          final dataService = Provider.of<IDataService>(context, listen: false);
          final imagePickerService = Provider.of<IImagePickerService>(context, listen: false);
          final imageDataService = Provider.of<IImageDataService>(context, listen: false);
          final tempFileService = Provider.of<ITemporaryFileService>(context, listen: false);

          return EditRoomViewModel(
            dataService: dataService,
            imagePickerService: imagePickerService,
            imageDataService: imageDataService, // Pass it here
            tempFileService: tempFileService, // Pass it here
            parentLocation: parentLocation,
            initialRoom: initialRoom,
          );
        }();

    return ChangeNotifierProvider<EditRoomViewModel>.value(
      value: effectiveViewModel,
      child: Consumer<EditRoomViewModel>(
        builder: (context, viewModel, child) {
          return PopScope(
            canPop: viewModel.isSaving ? false : !viewModel.hasUnsavedChanges,
            onPopInvokedWithResult: (bool didPop, Object? result) async {
              _logger.finer(
                "PopScope (onPopInvokedWithResult): Pop invoked for EditRoomPage. DidPop: $didPop, Unsaved: ${viewModel.hasUnsavedChanges}, Saving: ${viewModel.isSaving}. Result: $result",
              );
              if (didPop) {
                // This means pop was allowed by canPop OR it was a system back gesture that wasn't prevented
                await viewModel.handleDiscardOrPop();
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: Text(viewModel.appBarTitle),
                leading: BackButton(
                  onPressed: () async {
                    if (await _onWillPop(context, viewModel)) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: viewModel.formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildFormFields(context, viewModel),
                      const SizedBox(height: 24.0),
                      _buildImageSection(context, viewModel), // Integrate the image section
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
