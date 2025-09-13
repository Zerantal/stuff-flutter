// lib/features/item/pages/item_details_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';
import '../../../services/contracts/temporary_file_service_interface.dart';
import '../../../shared/forms/decoration.dart';
import '../../../shared/forms/validators.dart';
import '../../../shared/widgets/edit_entity_scaffold.dart';
import '../../../shared/widgets/image_manager_input.dart';
import '../../../shared/widgets/image_thumb.dart';
import '../../../shared/widgets/initial_load_error_panel.dart';
import '../../../shared/widgets/loading_scaffold.dart';
import '../viewmodels/item_details_view_model.dart';

class ItemDetailsPage extends StatefulWidget {
  final String? itemId;

  const ItemDetailsPage({super.key, this.itemId});

  @override
  State<ItemDetailsPage> createState() => _ItemDetailsPageState();
}

class _ItemDetailsPageState extends State<ItemDetailsPage> {
  String? get itemId => widget.itemId;

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
    final vm = context.read<ItemDetailsViewModel>();
    final isInitialised = context.select<ItemDetailsViewModel, bool>((m) => m.isInitialised);
    final initialLoadError = context.select<ItemDetailsViewModel, Object?>(
      (m) => m.initialLoadError,
    );

    const pageKey = ValueKey('ItemDetailsPage');

    // 1) Loading (before init completes)
    if (!isInitialised && initialLoadError == null) {
      return const LoadingScaffold(key: pageKey, title: 'Edit Item');
    }

    // 2) Error (init failed)
    if (initialLoadError != null) {
      return InitialLoadErrorPanel(
        key: pageKey,
        title: 'Edit Item',
        message: 'Could not load item.',
        details: initialLoadError.toString(),
        onRetry: () async => vm.retryInit(),
        onClose: () => Navigator.of(context).maybePop(),
      );
    }

    // VM will have been initialised by now. Can
    final isSaving = context.select<ItemDetailsViewModel, bool>((m) => m.isSaving);
    final isNewItem = context.select<ItemDetailsViewModel, bool>((m) => m.isNewItem);
    final isViewOnly = context.select<ItemDetailsViewModel, bool>((m) => !m.isEditable);
    final hasUnsavedChanges = context.select<ItemDetailsViewModel, bool>(
      (m) => m.hasUnsavedChanges,
    );

    final isBusy = isSaving;

    return EditEntityScaffold(
      key: pageKey,
      title: isNewItem
          ? 'Add Item'
          : isViewOnly
          ? 'Item Details'
          : 'Edit Item',
      isCreate: isNewItem,
      isBusy: isBusy,
      isViewOnly: isViewOnly,
      hasUnsavedChanges: hasUnsavedChanges,
      onDelete: (isNewItem || isViewOnly) ? null : vm.deleteItem,
      onSave: vm.saveState,
      onEdit: isViewOnly
          ? () {
              if (widget.itemId != null) {
                AppRoutes.itemEdit.pushReplacement(context, pathParams: {'itemId': widget.itemId!});
              }
            }
          : null,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _DetailsForm(vm: vm, isViewOnly: isViewOnly),
      ),
    );
  }
}

class _DetailsForm extends StatelessWidget {
  const _DetailsForm({required this.vm, required this.isViewOnly});

  final ItemDetailsViewModel vm;
  final bool isViewOnly;

  @override
  Widget build(BuildContext context) {
    final disabled = context.select<ItemDetailsViewModel, bool>((m) => m.isSaving);
    final state = vm.currentState;

    return Form(
      key: isViewOnly ? null : vm.formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- Name field ---
          isViewOnly
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Name', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(state.name, style: Theme.of(context).textTheme.titleMedium),
                  ],
                )
              : TextFormField(
                  key: const Key('item_name'),
                  controller: vm.nameController.raw,
                  decoration: entityDecoration(label: 'Name', hint: 'e.g., Tv, Fridge'),
                  textInputAction: TextInputAction.next,
                  validator: requiredMax(50),
                  enabled: !disabled,
                ),
          const SizedBox(height: 16),

          // --- Description field ---
          isViewOnly
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Description', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(state.description.isEmpty ? '—' : state.description),
                  ],
                )
              : TextFormField(
                  key: const Key('item_description'),
                  controller: vm.descriptionController.raw,
                  decoration: entityDecoration(label: 'Description', hint: 'Optional notes...'),
                  textInputAction: TextInputAction.newline,
                  validator: optionalMax(250),
                  maxLines: 3,
                  enabled: !disabled,
                ),
          const SizedBox(height: 20),

          // --- Images ---
          isViewOnly
              ? Selector<ItemDetailsViewModel, int>(
                  selector: (_, m) => m.imageListRevision,
                  builder: (context, rev, _) {
                    final images = state.images;
                    if (images.refs.isEmpty) {
                      return const Text('No images');
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: images.refs.map((img) {
                        return ImageThumb(image: img, width: 100, height: 100);
                      }).toList(),
                    );
                  },
                )
              : Selector<ItemDetailsViewModel, (bool, TempSession?, int)>(
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
                      placeholderAsset: 'assets/images/image_placeholder.jpg',
                    );
                  },
                ),
        ],
      ),
    );
  }
}
