// lib/features/contents/widgets/thumb_from_guids.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/image/image_ref.dart';
import '../../../services/contracts/image_data_service_interface.dart';

class ThumbFromGuids extends StatelessWidget {
  const ThumbFromGuids(this.guids, {this.size, this.radius = 10, super.key});

  /// If null, it will expand to parent’s constraints (good for grid header).
  final double? size;
  final double radius;
  final List<String> guids;

  @override
  Widget build(BuildContext context) {
    if (guids.isEmpty) {
      return _fallback();
    }
    final ref = context.read<IImageDataService>().refForGuid(guids.first);
    final img = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: buildImage(ref, fit: BoxFit.cover),
    );
    if (size == null) return img;
    return SizedBox(width: size, height: size, child: img);
  }

  Widget _fallback() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), color: Colors.black12),
    child: const Icon(Icons.photo_outlined),
  );
}
