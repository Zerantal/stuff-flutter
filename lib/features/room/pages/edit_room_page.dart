// lib/features/room/pages/edit_room_page.dart (updated to reuse shared styling)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/image_manager_input.dart';
import '../../../shared/forms/decoration.dart';
import '../../../shared/forms/validators.dart';
import '../../../shared/widgets/initial_load_error_panel.dart';
import '../../../shared/widgets/loading_scaffold.dart';
import '../viewmodels/edit_room_view_model.dart';

class EditRoomPage extends StatefulWidget {
  const EditRoomPage({super.key, this.roomId});

  final String? roomId;

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
    final vm = context.watch<EditRoomViewModel>();

    // 1) Loading (before init completes)
    if (!vm.isInitialised && vm.initialLoadError == null) {
      return const LoadingScaffold(title: 'Edit Room');
    }

    // 2) Error (init failed)
    if (vm.initialLoadError != null) {
      return InitialLoadErrorPanel(
        title: 'Edit Room',
        message: 'Could not load room.',
        details: vm.initialLoadError.toString(),
        onRetry: (roomId == null) ? null : () => vm.retryInitForEdit(roomId!),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final isBusy = vm.isSaving;

    return EditEntityScaffold(
      title: vm.isNewRoom ? 'Add Room' : 'Edit Room',
      isCreate: vm.isNewRoom,
      isBusy: isBusy,
      hasUnsavedChanges: vm.hasUnsavedChanges,
      onDelete: (vm.isNewRoom) ? null : vm.deleteRoom,
      onSave: vm.saveState,
      body: _EditForm(vm: vm),
    );
  }
}

/// The main form body: name, description, address row (with GPS), image manager, etc.
class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm});

  final EditRoomViewModel vm;

  @override
  Widget build(BuildContext context) {
    final disabled = vm.isSaving;

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('room_name'),
            controller: vm.nameController.raw,
            decoration: entityDecoration(label: 'Name', hint: 'e.g., Kitchen'),
            textInputAction: TextInputAction.next,
            validator: requiredMax(100),
            enabled: !disabled,
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('room_description'),
            controller: vm.descriptionController.raw,
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
              images: vm.currentState.images,
              onRemoveAt: vm.onRemoveAt,
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
    );
  }
}
