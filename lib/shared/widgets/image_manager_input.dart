// lib/shared/widgets/image_manager_input.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/image_identifier.dart';
import '../../services/contracts/image_data_service_interface.dart';
import '../../services/contracts/image_picker_service_interface.dart';
import '../../services/contracts/temporary_file_service_interface.dart';
import '../image/image_ref.dart';
import '../image/image_picker_controller.dart';
import '../image/pick_result.dart';
import 'image_thumb.dart';

/// Reusable image manager (grid of thumbnails + “Add” tile).
/// - Displays [images] (as ImageRef) with remove affordance.
/// - Performs picking *internally* (camera/gallery) using services from Provider.
/// - Emits a single [onImagePicked] callback with both the ImageIdentifier (GUID or Temp)
///   and a ready-to-use ImageRef for the UI.
class ImageManagerInput extends StatelessWidget {
  const ImageManagerInput({
    super.key,
    required this.session,
    required this.images,
    required this.onRemoveAt,
    required this.onImagePicked,
    this.tileSize = 92,
    this.spacing = AppSpacing.sm,
    this.placeholderAsset,
  });

  final TempSession session;
  final List<ImageRef> images;
  final void Function(int index) onRemoveAt;

  /// Called when a new image was picked by the widget (camera/gallery).
  /// Provides both the identifier (TempFileIdentifier or GuidIdentifier) and the UI-ready ImageRef.
  final void Function(ImageIdentifier id, ImageRef ref) onImagePicked;

  final double tileSize;
  final double spacing;
  final String? placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      for (var i = 0; i < images.length; i++)
        _ThumbTile(
          key: Key('img_tile_$i'),
          image: images[i],
          size: tileSize,
          placeholderAsset: placeholderAsset,
          onRemove: () => onRemoveAt(i),
        ),
      _AddTile(
        key: const Key('img_tile_add'),
        session: session,
        size: tileSize,
        onPicked: onImagePicked,
        placeholderAsset: placeholderAsset,
      ),
    ];

    return Wrap(spacing: spacing, runSpacing: spacing, children: items);
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    super.key,
    required this.image,
    required this.size,
    required this.onRemove,
    this.placeholderAsset,
  });

  final ImageRef image;
  final double size;
  final VoidCallback onRemove;
  final String? placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero, // override only margin
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: size,
              height: size,
              child: ImageThumb(
                image: image,
                width: size,
                height: size,
                borderRadius: BorderRadius.circular(AppRadius.md),
                loadingWidget: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (placeholderAsset == null)
                    ? Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.error)
                    : Image.asset(placeholderAsset!, width: size, height: size, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned(
            top: -AppOverlay.offset,
            right: -AppOverlay.offset,
            child: IconButton.filledTonal(
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    super.key,
    required this.session,
    required this.size,
    required this.onPicked,
    this.placeholderAsset,
  });

  final TempSession session;
  final double size;
  final void Function(ImageIdentifier id, ImageRef ref) onPicked;
  final String? placeholderAsset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Grab dependencies *before* we await anything (avoids context-after-await lints)
    final picker = context.read<IImagePickerService>();
    final store = context.read<IImageDataService>();

    // Local controller for this tile (keeps widget self-contained)
    final controller = ImagePickerController(picker: picker, store: store, session: session);

    Future<void> handleAction(_AddAction action) async {
      final r = action == _AddAction.camera
          ? await controller.pickFromCamera()
          : await controller.pickFromGallery();

      if (r is PickCancelled || r is PickFailed) return;

      if (r is PickedTemp) {
        final id = TempImageIdentifier(r.file);
        final ref = ImageRef.file(r.file.path);
        onPicked(id, ref);
      } else if (r is SavedGuid) {
        final ref =
            await store.getImage(r.guid, verifyExists: true) ??
            (placeholderAsset == null
                ? const ImageRef.asset('assets/images/location_placeholder.jpg')
                : ImageRef.asset(placeholderAsset!));
        onPicked(PersistedImageIdentifier(r.guid), ref);
      }
    }

    Future<void> showPickerSheet() async {
      final action = await showModalBottomSheet<_AddAction>(
        context: context,
        builder: (ctx) {
          return SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Pick from Gallery'),
                  onTap: () async {
                    context.pop();
                    await handleAction(_AddAction.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take Photo'),
                  onTap: () async {
                    context.pop();
                    await handleAction(_AddAction.camera);
                  },
                ),
              ],
            ),
          );
        },
      );
      if (action != null) await handleAction(action);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppOverlay.radius)),
        color: theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppOverlay.radius),
          onTap: showPickerSheet,
          child: Icon(
            Icons.add_a_photo_outlined,
            size: size * 0.45, // scales icon size relative to tile
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

enum _AddAction { gallery, camera }
