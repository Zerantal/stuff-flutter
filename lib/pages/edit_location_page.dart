// lib/pages/edit_location_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../services/data_service_interface.dart';
import '../services/image_data_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../viewmodels/edit_location_view_model.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/image_manager_input.dart';

// If your project stores the placeholder in a different path/case, adjust here:
const _kLocationPlaceholderAsset = 'Assets/images/location_placeholder.jpg';
final _log = Logger('EditLocationPage');

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
  TempSession? _session;

  final _uuid = const Uuid();

  @override
  initState() {
    super.initState();
    _createTempSession();
  }

  Future<void> _createTempSession() async {
    final temp = context.read<ITemporaryFileService>();
    final String shortId = (locationId != null) ? locationId!.substring(0, 10) : '';

    final sessionLabel =
        'edit_location_$shortId'
        '_${_uuid.v4().substring(0, 10)}';
    final s = await temp.startSession(label: sessionLabel);
    if (!mounted) return;
    setState(() => _session = s);
  }

  @override
  void dispose() {
    // Always safe to cleanup (after Save the session should be empty).
    _session?.dispose(deleteContents: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If your DI already provides the VM, remove this provider and just return _EditLocationScaffold.
    return ChangeNotifierProvider<EditLocationViewModel>(
      create: (ctx) => EditLocationViewModel(
        dataService: ctx.read<IDataService>(),
        imageDataService: ctx.read<IImageDataService>(),
        locationService: ctx.read<ILocationService>(),
        locationId: locationId,
      )..init(),
      child: _EditLocationScaffold(session: _session),
    );
  }
}

/// Wraps app bar, body, and FAB; keeps build simple and declarative.
class _EditLocationScaffold extends StatelessWidget {
  const _EditLocationScaffold({required TempSession? session}) : _session = session;

  final TempSession? _session;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditLocationViewModel>();
    final isBusy = vm.isSaving || vm.isGettingLocation;
    final isLoading = vm.isInitialising;

    return PopScope(
      // If there are no unsaved changes, allow the system back to pop immediately.
      canPop: !vm.hasUnsavedChanges,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return; // system already popped

        final nav = Navigator.of(context); // capture before awaiting
        final discard = await ConfirmationDialog.show(
          context,
          title: 'Discard changes?',
          message: 'You have unsaved changes. Discard them and leave?',
          confirmText: 'Discard',
          cancelText: 'Cancel',
        );
        if (!context.mounted) return;

        if (discard == true && nav.canPop()) {
          nav.pop();
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(vm.isNewLocation ? 'Add Location' : 'Edit Location'),
          actions: [
            if (!vm.isNewLocation)
              IconButton(
                key: const Key('delete_location_btn'),
                tooltip: 'Delete',
                icon: const Icon(Icons.delete_outline),
                onPressed: (isLoading || isBusy) ? null : () => _confirmDelete(context, vm),
              ),
          ],
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isLoading
              ? const Center(key: ValueKey('edit_loc_spinner'), child: CircularProgressIndicator())
              : Stack(
                  children: [
                    _EditForm(vm: vm, session: _session),
                    if (isBusy)
                      const IgnorePointer(
                        child: ColoredBox(
                          color: Color(0x33000000),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('save_location_fab'),
          onPressed: (!isLoading && !vm.isSaving) ? () => _save(context, vm) : null,
          icon: const Icon(Icons.save_outlined),
          label: Text(vm.isNewLocation ? 'Create' : 'Save'),
        ),
      ),
    );
  }
}

/// The main form body: name, description, address row (with GPS), image manager, etc.
class _EditForm extends StatelessWidget {
  const _EditForm({required this.vm, required TempSession? session}) : _session = session;
  final EditLocationViewModel vm;
  final TempSession? _session;

  @override
  Widget build(BuildContext context) {
    final disabled = vm.isInitialising || vm.isSaving;

    return Form(
      key: vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            key: const Key('loc_name'),
            controller: vm.nameController,
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
            controller: vm.descriptionController,
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
                  controller: vm.addressController,
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
                          final ok = await vm.getCurrentAddress();
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

          // Reuse your shared widget for the image grid + add actions.
          if (_session == null)
            const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            ImageManagerInput(
              key: const Key('image_manager'),
              session: _session!,
              images: vm.images,
              onRemoveAt: vm.removeImage,
              onImagePicked: vm.onImagePicked,
              tileSize: 92,
              spacing: 8,
              placeholderAsset: _kLocationPlaceholderAsset,
            ),
        ],
      ),
    );
  }
}

Future<void> _save(BuildContext context, EditLocationViewModel vm) async {
  final messenger = ScaffoldMessenger.of(context);
  final nav = Navigator.of(context);

  final ok = await vm.saveLocation();
  if (!context.mounted) return;

  if (ok) {
    messenger.showSnackBar(
      SnackBar(content: Text(vm.isNewLocation ? 'Location created' : 'Location saved')),
    );
    if (nav.canPop()) nav.pop();
  } else {
    messenger.showSnackBar(const SnackBar(content: Text('Please fix the errors and try again.')));
  }
}

Future<void> _confirmDelete(BuildContext context, EditLocationViewModel vm) async {
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  final yes = await ConfirmationDialog.show(
    context,
    title: 'Delete location?',
    message: 'This cannot be undone.',
    confirmText: 'Delete',
    cancelText: 'Cancel',
    danger: true,
  );

  if (yes == true) {
    try {
      // If you add a vm.delete() later, call it here.
      messenger.showSnackBar(const SnackBar(content: Text('Location deleted')));
      if (nav.canPop()) nav.pop();
    } catch (e, s) {
      _log.severe('Delete failed', e, s);
      messenger.showSnackBar(const SnackBar(content: Text('Failed to delete location')));
    }
  }
}
