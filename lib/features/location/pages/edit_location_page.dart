// lib/features/location/pages/edit_location_page.dart
import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/initial_load_error_panel.dart';
import '../../../shared/widgets/loading_scaffold.dart';
import '../viewmodels/edit_location_view_model.dart';
import '../../../shared/widgets/image_manager_input.dart';

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
    final vm = context.watch<EditLocationViewModel>();

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
        onRetry: (locationId == null) ? null : () => vm.retryInitForEdit(locationId!),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    final isBusy = vm.isSaving || vm.isGettingLocation;

    return EditEntityScaffold(
      title: vm.isNewLocation ? 'Add Location' : 'Edit Location',
      isCreate: vm.isNewLocation,
      isBusy: isBusy,
      hasUnsavedChanges: vm.hasUnsavedChanges,
      onDelete: (vm.isNewLocation) ? null : vm.deleteLocation,
      onSave: vm.saveState,
      body: vm.isInitialised ? _EditForm(vm: vm) : const Center(child: CircularProgressIndicator()),
    );
  }
}

/// The main form body: name, description, address row (with GPS), image manager, etc.
class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm});
  final EditLocationViewModel vm;

  @override
  Widget build(BuildContext context) {
    final disabled = vm.isSaving;

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('loc_name'),
            controller: vm.nameController.raw,
            enabled: !disabled,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Office, Garage, Storage Unit',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Name is required';
              if (s.length > 100) return 'Keep it under 100 characters';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('loc_desc'),
            controller: vm.descriptionController.raw,
            enabled: !disabled,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Optional notes…',
              border: OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: 12),
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
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Use current location',
                child: ElevatedButton.icon(
                  key: const Key('use_current_location_btn'),
                  onPressed: vm.isGettingLocation
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
                  icon: vm.isGettingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: const Text('Use\nGPS', textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(72, 56)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (vm.hasTempSession)
            ImageManagerInput(
              key: const Key('image_manager'),
              session: vm.tempSession!,
              images: vm.currentState.images,
              onRemoveAt: vm.onRemoveAt,
              onImagePicked: vm.onImagePicked,
              tileSize: 92,
              spacing: 8,
              placeholderAsset: _kLocationPlaceholderAsset,
            )
          else
            const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}
