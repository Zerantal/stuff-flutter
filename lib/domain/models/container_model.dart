// lib/domain/models/container_model.dart
import 'package:meta/meta.dart';
import '../../core/models/base_model.dart';

@immutable
class Container extends BaseModel<Container> {
  final String roomId;
  final String? parentContainerId;
  final String name;
  final String? description;
  final List<String> imageGuids;
  final int? positionIndex;

  Container({
    super.id,
    super.createdAt,
    super.updatedAt,
    required this.roomId,
    this.parentContainerId,
    required this.name,
    this.description,
    this.imageGuids = const <String>[],
    this.positionIndex,
  });

  Container copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? roomId,
    String? parentContainerId,
    String? name,
    String? description,
    List<String>? imageGuids,
    int? positionIndex,
  }) {
    return Container(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roomId: roomId ?? this.roomId,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageGuids: imageGuids ?? this.imageGuids,
      positionIndex: positionIndex ?? this.positionIndex,
    );
  }

  @protected
  @override
  Container copyWithUpdatedAt(DateTime nextUpdatedAt) {
    return copyWith(updatedAt: nextUpdatedAt);
  }
}
