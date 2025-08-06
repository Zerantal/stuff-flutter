// lib/core/models/base_model.dart
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

abstract class BaseModel extends HiveObject {
  /// A unique ID
  @HiveField(0)
  final String id;

  /// When this record was first created
  @HiveField(1)
  final DateTime createdAt;

  /// Last time it was saved()
  @HiveField(2)
  DateTime updatedAt;

  BaseModel({String? id, DateTime? createdAt, DateTime? updatedAt})
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
      updatedAt = updatedAt ?? DateTime.now();

  /// Call this to bump the updatedAt timestamp
  void touch() => updatedAt = DateTime.now();

  @override
  Future<void> save() {
    touch();
    return super.save();
  }
}
