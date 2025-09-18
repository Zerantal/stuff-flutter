// lib/features/location/pages/edit_location_page.dart

import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/initial_load_error_panel.dart';
import '../../../shared/widgets/loading_scaffold.dart';
import '../../../shared/widgets/image_manager_input.dart';
import '../viewmodels/edit_location_view_model.dart';

const _kLocationPlaceholderAsset = 'assets/images/location_placeholder.jpg';
// final _log = Logger('EditLocationPage');

/// Accepts an optional [locationId]. If null => creating a new location.
/// If not null => editing existing; we’ll show a spinner while data loads.
class EditLocationPage extends StatefulWidget {
  const EditLocationPage({super.key, this.locationId});

  final String? locationId;

  @override
  State<EditLocationPage> createState() => _EditLocationPageState();
}

class _EditLocationPageState extends State<EditLocationPage> {
  String? get locationId => widget.locationId;

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
    final vm = context.read<EditLocationViewModel>();
    final isInitialised = context.select<EditLocationViewModel, bool>((m) => m.isInitialised);
    final initialLoadError = context.select<EditLocationViewModel, Object?>(
      (m) => m.initialLoadError,
    );

    const pageKey = ValueKey('EditLocationPage');

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
        onRetry: (locationId == null) ? null : () => vm.retryInitForEdit(locationId!),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    // VM will have been initialised by now. Can
    final isSaving = context.select<EditLocationViewModel, bool>((m) => m.isSaving);
    final isGettingLocation = context.select<EditLocationViewModel, bool>(
      (m) => m.isGettingLocation,
    );
    final isNewLocation = context.select<EditLocationViewModel, bool>((m) => m.isNewLocation);
    final hasUnsavedChanges = context.select<EditLocationViewModel, bool>(
      (m) => m.hasUnsavedChanges,
    );

    final isBusy = isSaving || isGettingLocation;

    return EditEntityScaffold(
      key: pageKey,
      title: isNewLocation ? 'Add Location' : 'Edit Location',
      isCreate: isNewLocation,
      isBusy: isBusy,
      hasUnsavedChanges: hasUnsavedChanges,
      onDelete: (isNewLocation) ? null : vm.deleteLocation,
      onSave: vm.saveState,
      body: _EditForm(vm: vm),
    );
  }
}

/// The main form body: name, description, address row (with GPS), image manager, etc.
class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm});
  final EditLocationViewModel vm;

  @override
  Widget build(BuildContext context) {
    final disabled = context.select<EditLocationViewModel, bool>((m) => m.isSaving);
    final isGettingLocation = context.select<EditLocationViewModel, bool>(
      (m) => m.isGettingLocation,
    );

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextFormField(
            key: const Key('loc_name'),
            controller: vm.nameController.raw,
            enabled: !disabled,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Office, Garage, Storage Unit',
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Name is required';
              if (s.length > 100) return 'Keep it under 100 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          TextFormField(
            key: const Key('loc_desc'),
            controller: vm.descriptionController.raw,
            enabled: !disabled,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Optional notes…',
              alignLabelWithHint: true,
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  key: const Key('loc_address'),
                  controller: vm.addressController.raw,
                  enabled: !disabled,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: 'e.g., 123 Main St, Anytown',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Use current location',
                child: ElevatedButton.icon(
                  key: const Key('use_current_location_btn'),
                  onPressed: isGettingLocation
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await vm.acquireCurrentAddress();
                          if (!context.mounted) return;
                          if (!ok) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Unable to get current location')),
                            );
                          }
                        },
                  icon: isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: const Text('Use\nGPS', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Images block: only rebuild when session/images change.
          Selector<EditLocationViewModel, (bool, TempSession?, int)>(
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
                placeholderAsset: _kLocationPlaceholderAsset,
              );
            },
          ),
        ],
      ),
    );
  }
}
