// lib/core/models/base_model.dart
import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';
import 'package:clock/clock.dart';

abstract class BaseModel<T extends BaseModel<T>> {
  final String id;
  final DateTime createdAt; // UTC
  final DateTime updatedAt; // UTC

  /// Single ctor: base fields are optional and auto-generated if omitted.
  BaseModel({String? id, DateTime? createdAt, DateTime? updatedAt})
    : id = id ?? _newId(),
      createdAt = _toUtc(createdAt) ?? _nowUtc(),
      updatedAt = _normalizeUpdated(updatedAt, _toUtc(createdAt) ?? _nowUtc());

  // ---- Infrastructure-only hooks ----

  /// Subclasses must return a copy with only updatedAt changed.
  @protected
  T copyWithUpdatedAt(DateTime updatedAt);

  /// Return a copy with updatedAt bumped to now (UTC), never earlier than createdAt.
  T withTouched() {
    final now = _nowUtc();
    final next = now.isBefore(createdAt) ? createdAt : now;
    return copyWithUpdatedAt(next);
  }

  // ---------- Identity-only equality & hashing ----------
  @nonVirtual
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BaseModel && other.runtimeType == runtimeType && other.id == id);

  @nonVirtual
  @override
  int get hashCode => Object.hash(runtimeType, id);

  @nonVirtual
  @override
  String toString() => '$runtimeType(id: $id)';

  // ---- Utilities ----
  static String _newId() => const Uuid().v4();
  static DateTime _nowUtc() => clock.now().toUtc();
  static DateTime? _toUtc(DateTime? dt) => dt?.toUtc();

  /// Ensure updatedAt is not before createdAt (handles odd inputs / clock skew).
  static DateTime _normalizeUpdated(DateTime? updated, DateTime created) {
    final u = _toUtc(updated) ?? _nowUtc();
    return u.isBefore(created) ? created : u;
  }
}
