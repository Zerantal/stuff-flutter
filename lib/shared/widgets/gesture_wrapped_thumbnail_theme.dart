// lib/shared/widgets/gesture_wrapped_thumbnail_theme.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../image/image_ref.dart';

/// Theme extension for GestureWrappedThumbnail.
/// Allows overriding defaults like size, border radius, and background color.
class GestureWrappedThumbnailTheme extends ThemeExtension<GestureWrappedThumbnailTheme> {
  final double size;
  final double borderRadius;
  final BoxFit fit;
  final Color? backgroundColor;
  final ImageRef? placeholder;

  const GestureWrappedThumbnailTheme({
    this.size = 80,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.sm,
    this.backgroundColor,
    this.placeholder,
  });

  @override
  GestureWrappedThumbnailTheme copyWith({
    double? size,
    double? borderRadius,
    BoxFit? fit,
    Color? backgroundColor,
    ImageRef? placeholder,
  }) {
    return GestureWrappedThumbnailTheme(
      size: size ?? this.size,
      borderRadius: borderRadius ?? this.borderRadius,
      fit: fit ?? this.fit,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      placeholder: placeholder ?? this.placeholder,
    );
  }

  @override
  GestureWrappedThumbnailTheme lerp(covariant GestureWrappedThumbnailTheme? other, double t) {
    if (other is! GestureWrappedThumbnailTheme) return this;
    return GestureWrappedThumbnailTheme(
      size: lerpDouble(size, other.size, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      fit: t < 0.5 ? fit : other.fit,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      placeholder: t < 0.5 ? placeholder : other.placeholder,
    );
  }

  static GestureWrappedThumbnailTheme of(BuildContext context) {
    return Theme.of(context).extension<GestureWrappedThumbnailTheme>() ??
        const GestureWrappedThumbnailTheme();
  }
}
