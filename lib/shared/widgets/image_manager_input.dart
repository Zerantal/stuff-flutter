// lib/shared/widgets/image_manager_input.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../image/image_ref.dart';
import '../../core/image_identifier.dart';
import '../image/image_picker_controller.dart';
import '../image/pick_result.dart';
import '../../services/contracts/image_data_service_interface.dart';
import '../../services/contracts/image_picker_service_interface.dart';
import '../../services/contracts/temporary_file_service_interface.dart';
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
    this.spacing = 8,
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
    final items = <Widget>[];

    for (var i = 0; i < images.length; i++) {
      items.add(
        _ThumbTile(
          key: Key('img_tile_$i'),
          image: images[i],
          size: tileSize,
          placeholderAsset: placeholderAsset,
          onRemove: () => onRemoveAt(i),
        ),
      );
    }

    items.add(
      _AddTile(
        key: const Key('img_tile_add'),
        session: session,
        size: tileSize,
        spacing: spacing,
        placeholderAsset: placeholderAsset,
        onPicked: onImagePicked,
      ),
    );

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: size,
            height: size,
            child: ImageThumb(
              image: image,
              width: size,
              height: size,
              borderRadius: BorderRadius.circular(8),
              loadingWidget: SizedBox(
                width: size,
                height: size,
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (placeholderAsset == null)
                  ? const Center(child: Icon(Icons.broken_image_outlined))
                  : Image(
                      image: AssetImage(placeholderAsset!),
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: IconButton.filledTonal(
            tooltip: 'Remove',
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(padding: EdgeInsets.zero, fixedSize: const Size(28, 28)),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    super.key,
    required this.session,
    required this.size,
    required this.spacing,
    required this.onPicked,
    this.placeholderAsset,
  });

  final TempSession session;
  final double size;
  final double spacing;
  final void Function(ImageIdentifier id, ImageRef ref) onPicked;
  final String? placeholderAsset;

  @override
  Widget build(BuildContext context) {
    // Grab dependencies *before* we await anything (avoids context-after-await lints)
    final picker = context.read<IImagePickerService>();
    final store = context.read<IImageDataService>();

    // Local controller for this tile (keeps widget self-contained)
    final controller = ImagePickerController(picker: picker, store: store, session: session);

    Future<void> handleAction(_AddAction action) async {
      PickResult r;
      if (action == _AddAction.camera) {
        r = await controller.pickFromCamera();
      } else {
        r = await controller.pickFromGallery();
      }

      if (r is PickCancelled) return;

      if (r is PickFailed) {
        // Silent fail (or show a SnackBar if you prefer)
        return;
      }

      if (r is PickedTemp) {
        final id = TempFileIdentifier(r.file);
        final ref = ImageRef.file(r.file.path);
        onPicked(id, ref);
        return;
      }

      if (r is SavedGuid) {
        // Resolve to ImageRef via store, otherwise fall back to a placeholder
        ImageRef? ref;
        ref = await store.getImage(r.guid, verifyExists: true);
        ref ??= (placeholderAsset == null)
            ? const ImageRef.asset('assets/images/location_placeholder.jpg')
            : ImageRef.asset(placeholderAsset!);

        onPicked(GuidIdentifier(r.guid), ref);
        return;
      }
    }

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final action = await showMenu<_AddAction>(
              context: context,
              position: const RelativeRect.fromLTRB(200, 200, 0, 0),
              items: const [
                PopupMenuItem(value: _AddAction.gallery, child: Text('Pick from Gallery')),
                PopupMenuItem(value: _AddAction.camera, child: Text('Take Photo')),
              ],
            );
            if (action != null) {
              await handleAction(action);
            }
          },
          child: const Center(child: Icon(Icons.add_a_photo_outlined)),
        ),
      ),
    );
  }
}

enum _AddAction { gallery, camera }
