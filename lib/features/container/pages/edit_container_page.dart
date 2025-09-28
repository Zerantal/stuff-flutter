// lib/features/container/pages/edit_container_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/forms/decoration.dart';
import '../../../shared/forms/validators.dart';
import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/image_manager_input.dart';
import '../../../shared/widgets/initial_load_error_panel.dart';
import '../../../shared/widgets/loading_scaffold.dart';
import '../viewmodels/edit_container_view_model.dart';

class EditContainerPage extends StatefulWidget {
  final String? containerId;

  const EditContainerPage({super.key, this.containerId});

  @override
  State<EditContainerPage> createState() => _EditContainerPageState();
}

class _EditContainerPageState extends State<EditContainerPage> {
  String? get containerId => widget.containerId;

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
    final vm = context.read<EditContainerViewModel>();
    final isInitialised = context.select<EditContainerViewModel, bool>((m) => m.isInitialised);
    final initialLoadError = context.select<EditContainerViewModel, Object?>(
      (m) => m.initialLoadError,
    );

    const pageKey = ValueKey('EditContainerPage');

    // 1) Loading (before init completes)
    if (!isInitialised && initialLoadError == null) {
      return const LoadingScaffold(key: pageKey, title: 'Edit Container');
    }

    // 2) Error (init failed)
    if (initialLoadError != null) {
      return InitialLoadErrorPanel(
        key: pageKey,
        title: 'Edit Container',
        message: 'Could not load container.',
        details: initialLoadError.toString(),
        onRetry: (containerId == null) ? null : () async => await vm.retryInitForEdit(containerId!),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    // VM will have been initialised by now. Can
    final isSaving = context.select<EditContainerViewModel, bool>((m) => m.isSaving);
    final isNewContainer = context.select<EditContainerViewModel, bool>((m) => m.isNewContainer);
    final hasUnsavedChanges = context.select<EditContainerViewModel, bool>(
      (m) => m.hasUnsavedChanges,
    );

    final isBusy = isSaving;

    return EditEntityScaffold(
      key: pageKey,
      title: isNewContainer ? 'Add Container' : 'Edit Container',
      isCreate: isNewContainer,
      isBusy: isBusy,
      hasUnsavedChanges: hasUnsavedChanges,
      onDelete: (isNewContainer) ? null : vm.deleteContainer,
      onSave: vm.saveState,
      body: _EditForm(vm: vm),
    );
  }
}

/// The main form body: name, description, etc
class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm});

  final EditContainerViewModel vm;

  @override
  Widget build(BuildContext context) {
    final disabled = context.select<EditContainerViewModel, bool>((m) => m.isSaving);

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('container_name'),
            controller: vm.nameController.raw,
            decoration: entityDecoration(label: 'Name', hint: 'e.g., Toolbox'),
            textInputAction: TextInputAction.next,
            validator: requiredMax(50),
            enabled: !disabled,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('container_description'),
            controller: vm.descriptionController.raw,
            decoration: entityDecoration(label: 'Description', hint: 'Optional notes...'),
            textInputAction: TextInputAction.newline,
            validator: optionalMax(250),
            maxLines: 3,
            enabled: !disabled,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Image picker grid (uses the same component you use in Locations)
          Selector<EditContainerViewModel, (bool, TempSession?, int)>(
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
                spacing: 8,
                // Todo: create actual error placeholder image picker
                placeholderAsset: 'assets/images/image_placeholder.jpg',
              );
            },
          ),
        ],
      ),
    );
  }
}
