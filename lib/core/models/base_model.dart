// lib/core/models/base_model.dart
import 'package:uuid/uuid.dart';

abstract class BaseModel {
  /// A unique ID
  final String id;

  /// When this record was first created
  final DateTime createdAt;

  /// Last time it was saved()
  DateTime updatedAt;

  BaseModel({String? id, DateTime? createdAt, DateTime? updatedAt})
    : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
      updatedAt = updatedAt ?? DateTime.now();

  /// Call this to bump the updatedAt timestamp
  void touch() => updatedAt = DateTime.now();
}
