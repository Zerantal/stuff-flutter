// lib/features/room/pages/edit_room_page.dart (updated to reuse shared styling)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/image_manager_input.dart';
import '../../../shared/forms/decoration.dart';
import '../../../shared/forms/validators.dart';
import '../viewmodels/edit_room_view_model.dart';

class EditRoomPage extends StatefulWidget {
  const EditRoomPage({super.key, required this.locationId, this.roomId});
  final String locationId;
  final String? roomId; // null => create

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  String? get roomId => widget.roomId;

  @override
  initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => EditRoomViewModel(
        dataService: ctx.read<IDataService>(),
        imageDataService: ctx.read<IImageDataService>(),
        tempFileService: ctx.read<ITemporaryFileService>(),
        locationId: widget.locationId,
        roomId: widget.roomId,
      )..init(),
      child: _EditRoomScaffold(),
    );
  }
}

class _EditRoomScaffold extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditRoomViewModel>();
    final disabled = vm.isInitialising || vm.isSaving;

    return EditEntityScaffold(
      title: vm.isNewRoom ? 'Add Room' : 'Edit Room',
      isCreate: vm.isNewRoom,
      isBusy: vm.isSaving,
      hasUnsavedChanges: vm.hasUnsavedChanges,
      onDelete: (vm.isNewRoom) ? null : vm.deleteRoom,
      onSave: vm.saveRoom,
      body: vm.isInitialising
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: vm.formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    key: const Key('room_name'),
                    controller: vm.nameController,
                    decoration: entityDecoration(label: 'Name', hint: 'e.g., Kitchen'),
                    textInputAction: TextInputAction.next,
                    validator: requiredMax(100),
                    enabled: !disabled,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('room_description'),
                    controller: vm.descriptionController,
                    decoration: entityDecoration(label: 'Description', hint: 'Optional notes...'),
                    textInputAction: TextInputAction.newline,
                    validator: requiredMax(100),
                    maxLines: 3,
                    enabled: !disabled,
                  ),
                  const SizedBox(height: 20),
                  // Image picker grid (uses the same component you use in Locations)
                  if (vm.hasTempSession)
                    ImageManagerInput(
                      key: const Key('room_image_manager'),
                      session: vm.tempSession!,
                      images: vm.images,
                      onRemoveAt: vm.removeImage,
                      onImagePicked: vm.onImagePicked,
                      tileSize: 92,
                      spacing: 8,
                      placeholderAsset: 'assets/images/location_placeholder.jpg',
                    )
                  else
                    const SizedBox(
                      height: 90,
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                ],
              ),
            ),
    );
  }
}
