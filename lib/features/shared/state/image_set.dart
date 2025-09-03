// lib/features/shared/state/image_set.dart

import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import '../../../core/image_identifier.dart';
import '../../../services/utils/image_data_service_extensions.dart';
import '../../../shared/image/image_ref.dart';
import '../../../services/contracts/image_data_service_interface.dart';

@immutable
class ImageSet {
  final List<ImageIdentifier> _ids; // persisted or temp (truth for persistence)
  final List<ImageRef> _refs; // UI-ready images, index-aligned with ids

  UnmodifiableListView<ImageIdentifier> get ids => UnmodifiableListView(_ids);
  UnmodifiableListView<ImageRef> get refs => UnmodifiableListView(_refs);

  const ImageSet._(this._ids, this._refs);

  factory ImageSet.empty() => const ImageSet._(<ImageIdentifier>[], <ImageRef>[]);

  /// Construct from a list of persisted GUIDs (common for loading existing data).
  factory ImageSet.fromGuids(IImageDataService store, List<String> guids) {
    final ids = List<ImageIdentifier>.unmodifiable(
      guids.map((g) => PersistedImageIdentifier(g)).toList(growable: false),
    );
    final refs = List<ImageRef>.unmodifiable(store.refsForGuids(guids));
    return ImageSet._(ids, refs);
  }

  /// Construct from explicit parallel lists (e.g., from image-picking mixin).
  factory ImageSet.fromLists({required List<ImageIdentifier> ids, required List<ImageRef> refs}) {
    assert(ids.length == refs.length, 'ids and refs must have same length');
    return ImageSet._(List<ImageIdentifier>.unmodifiable(ids), List<ImageRef>.unmodifiable(refs));
  }

  int get length => _ids.length;
  bool get isEmpty => _ids.isEmpty;

  ImageSet copyWith({List<ImageIdentifier>? ids, List<ImageRef>? refs}) {
    if (ids != null && refs != null) {
      assert(ids.length == refs.length, 'ids and refs must have same length');
    }
    return ImageSet._(
      List<ImageIdentifier>.unmodifiable(ids ?? this._ids),
      List<ImageRef>.unmodifiable(refs ?? this._refs),
    );
  }

  /// Equality/dirty-tracking: by identifiers only (matches your previous logic).
  static const _idsEq = ListEquality<ImageIdentifier>();
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageSet && runtimeType == other.runtimeType && _idsEq.equals(_ids, other._ids);

  @override
  int get hashCode => _idsEq.hash(_ids);

  @override
  String toString() => 'ImageSet(len:$length)';
}
