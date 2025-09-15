// lib/features/room/pages/edit_room_page.dart (updated to reuse shared styling)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../App/theme.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
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
    final vm = context.read<EditRoomViewModel>();
    final isInitialised = context.select<EditRoomViewModel, bool>((m) => m.isInitialised);
    final initialLoadError = context.select<EditRoomViewModel, Object?>((m) => m.initialLoadError);

    const pageKey = ValueKey('EditRoomPage');

    // 1) Loading (before init completes)
    if (!isInitialised && initialLoadError == null) {
      return const LoadingScaffold(key: pageKey, title: 'Edit Room');
    }

    // 2) Error (init failed)
    if (initialLoadError != null) {
      return InitialLoadErrorPanel(
        key: pageKey,
        title: 'Edit Room',
        message: 'Could not load room.',
        details: initialLoadError.toString(),
        onRetry: (roomId == null) ? null : () async => await vm.retryInitForEdit(roomId!),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    // VM will have been initialised by now. Can
    final isSaving = context.select<EditRoomViewModel, bool>((m) => m.isSaving);
    final isNewRoom = context.select<EditRoomViewModel, bool>((m) => m.isNewRoom);
    final hasUnsavedChanges = context.select<EditRoomViewModel, bool>((m) => m.hasUnsavedChanges);

    final isBusy = isSaving;

    return EditEntityScaffold(
      key: pageKey,
      title: isNewRoom ? 'Add Room' : 'Edit Room',
      isCreate: isNewRoom,
      isBusy: isBusy,
      hasUnsavedChanges: hasUnsavedChanges,
      onDelete: (isNewRoom) ? null : vm.deleteRoom,
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
    final disabled = context.select<EditRoomViewModel, bool>((m) => m.isSaving);

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('room_name'),
            controller: vm.nameController.raw,
            decoration: entityDecoration(label: 'Name', hint: 'e.g., Kitchen'),
            textInputAction: TextInputAction.next,
            validator: requiredMax(100),
            enabled: !disabled,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('room_description'),
            controller: vm.descriptionController.raw,
            decoration: entityDecoration(label: 'Description', hint: 'Optional notes...'),
            textInputAction: TextInputAction.newline,
            validator: requiredMax(100),
            maxLines: 3,
            enabled: !disabled,
          ),
          const SizedBox(height: AppSpacing.md),
          // Image picker
          Selector<EditRoomViewModel, (bool, TempSession?, int)>(
            selector: (_, m) => (m.hasTempSession, m.tempSession, m.imageListRevision),
            builder: (context, s, _) {
              final hasSession = s.$1;
              final session = s.$2;

              if (!hasSession || session == null) {
                return const SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              final images = vm.currentState.images;

              return ImageManagerInput(
                key: ValueKey(s.$3),
                session: session,
                images: images.refs,
                onRemoveAt: vm.onRemoveAt,
                onImagePicked: vm.onImagePicked,
                tileSize: 92,
                spacing: AppSpacing.sm,
                placeholderAsset: 'assets/images/image_placeholder.jpg',
              );
            },
          ),
        ],
      ),
    );
  }
}
