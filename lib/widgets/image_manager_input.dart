// lib/widgets/image_manager_input.dart
import 'package:flutter/material.dart';
import '../core/helpers/image_ref.dart';

typedef ImageThumbnailBuilder =
    Widget Function(
      ImageRef imageIdentifier, {
      required double width,
      required double height,
      required BoxFit fit,
    });

class ImageManagerInput extends StatelessWidget {
  final List<ImageRef> currentImages;
  final ImageThumbnailBuilder imageThumbnailBuilder;
  final VoidCallback onAddImageFromCamera;
  final VoidCallback onAddImageFromGallery;
  final ValueChanged<int>
  onRemoveImage; // Passes the index of the image to remove
  final String title;
  final bool isLoading; // To disable buttons during operations

  const ImageManagerInput({
    super.key,
    required this.currentImages,
    required this.imageThumbnailBuilder,
    required this.onAddImageFromCamera,
    required this.onAddImageFromGallery,
    required this.onRemoveImage,
    this.title = 'Images',
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8.0),
        currentImages.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('No images yet. Add one!'),
                ),
              )
            : SizedBox(
                height: 120.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: currentImages.length,
                  itemBuilder: (context, index) {
                    final imageId = currentImages[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          Container(
                            width: 100.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7.0),
                              child: imageThumbnailBuilder(
                                imageId,
                                width: 100.0,
                                height: 100.0,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          // Remove Button
                          Padding(
                            padding: const EdgeInsets.all(2.0),
                            child: Material(
                              color:
                                  Colors.black54, // Semi-transparent background
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: isLoading
                                    ? null
                                    : () => onRemoveImage(index),
                                customBorder: const CircleBorder(),
                                child: const Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 12.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined),
              tooltip: 'Add Image from Camera',
              onPressed: isLoading ? null : onAddImageFromCamera,
              iconSize: 28,
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Add Image from Gallery',
              onPressed: isLoading ? null : onAddImageFromGallery,
              iconSize: 28,
            ),
            if (isLoading) // Optional: Show a small loading indicator next to buttons
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
