// lib/domain/models/item_model.dart
import 'package:meta/meta.dart';
import '../../core/models/base_model.dart';

@immutable
class Item extends BaseModel<Item> {
  final String roomId;
  final String? containerId; // null => directly in room
  final String name;
  final String? description; // requested
  final Map<String, dynamic> attrs;
  final List<String> imageGuids;
  final int? positionIndex;
  final bool isArchived;

  Item({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.roomId,
    this.containerId,
    required this.name,
    this.description,
    this.attrs = const <String, dynamic>{},
    this.imageGuids = const <String>[],
    this.positionIndex,
    this.isArchived = false,
  });

  Item copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? roomId,
    String? containerId,
    String? name,
    String? description,
    Map<String, dynamic>? attrs,
    List<String>? imageGuids,
    int? positionIndex,
    bool? isArchived,
  }) {
    return Item(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roomId: roomId ?? this.roomId,
      containerId: containerId ?? this.containerId,
      name: name ?? this.name,
      description: description ?? this.description,
      attrs: attrs ?? this.attrs,
      imageGuids: imageGuids ?? this.imageGuids,
      positionIndex: positionIndex ?? this.positionIndex,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @protected
  @override
  Item copyWithUpdatedAt(DateTime nextUpdatedAt) {
    return copyWith(updatedAt: nextUpdatedAt);
  }
}
