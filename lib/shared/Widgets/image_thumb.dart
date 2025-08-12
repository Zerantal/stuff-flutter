// lib/shared/Widgets/image_thumb.dart
//
// Reusable thumbnail widget for ImageRef sources.
// ViewModels should return ImageRef; this widget handles presentation.

import 'package:flutter/material.dart';

import '../image/image_ref.dart';

/// Small image thumbnail for grid/list usage.
/// - No storage knowledge: accepts an [ImageRef] only.
/// - Uses the shared [buildImage] helper for consistent loading/error UX.
/// - Shows [placeholderWidget] if [image] is null.
class ImageThumb extends StatelessWidget {
  /// The resolved image source from the ViewModel. If null, shows [placeholderWidget].
  final ImageRef? image;

  /// Target size.
  final double width;
  final double height;

  /// BoxFit for the thumbnail (defaults to cover).
  final BoxFit fit;

  /// Optional rounded corners.
  final BorderRadius? borderRadius;

  /// Optional tap handler.
  final VoidCallback? onTap;

  /// Optional Hero tag for shared element transitions.
  final String? heroTag;

  /// Shown while an image is loading (e.g., network).
  final Widget? loadingWidget;

  /// Shown when [image] is null.
  final Widget? placeholderWidget;

  /// Optional widget shown on error.
  final Widget? errorWidget;

  /// Optional cache sizing to reduce decode memory.
  final int? cacheWidth;
  final int? cacheHeight;

  /// Decorative options.
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;

  /// Clip behavior; defaults to [Clip.antiAlias].
  final Clip clipBehavior;

  const ImageThumb({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.onTap,
    this.heroTag,
    this.loadingWidget,
    this.placeholderWidget,
    this.errorWidget,
    this.cacheWidth,
    this.cacheHeight,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (image == null) {
      // No image -> show placeholder if provided, else an empty box
      content = placeholderWidget ?? const SizedBox(width: 20, height: 20);
    } else {
      // Build real image with loading/error handling
      content = buildImage(
        image!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        loadingWidget: loadingWidget,
        errorWidget: errorWidget,
      );
    }

    // Rounded corners if requested.
    if (borderRadius != null) {
      content = ClipRRect(borderRadius: borderRadius!, clipBehavior: clipBehavior, child: content);
    }

    // Optional background/padding/margin.
    content = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      color: backgroundColor,
      child: content,
    );

    // Optional hero wrapper.
    if (heroTag != null && heroTag!.isNotEmpty) {
      content = Hero(tag: heroTag!, child: content);
    }

    // Optional tap handling.
    if (onTap != null) {
      content = InkWell(onTap: onTap, borderRadius: borderRadius, child: content);
    }

    return content;
  }
}
