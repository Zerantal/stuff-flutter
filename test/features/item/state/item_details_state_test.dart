// test/features/item/state/item_details_state_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/core/image_identifier.dart';

import 'package:stuff/features/item/state/item_details_state.dart';
import 'package:stuff/features/shared/state/image_set.dart';
import 'package:stuff/shared/image/image_ref.dart';

void main() {
  group('ItemDetailsState', () {
    test('default constructor provides empty values', () {
      final state = ItemDetailsState();
      expect(state.name, '');
      expect(state.description, '');
      expect(state.images, ImageSet.empty());
    });

    test('copyWith updates only the provided fields', () {
      final initial = ItemDetailsState(name: 'Old', description: 'Desc1');

      final updatedName = initial.copyWith(name: 'New');
      expect(updatedName.name, 'New');
      expect(updatedName.description, 'Desc1');
      expect(updatedName.images, initial.images);

      final updatedDesc = initial.copyWith(description: 'Desc2');
      expect(updatedDesc.name, 'Old');
      expect(updatedDesc.description, 'Desc2');

      final newImages = ImageSet.empty(); // could be a non-empty one in future
      final updatedImages = initial.copyWith(images: newImages);
      expect(updatedImages.images, newImages);
      expect(updatedImages.name, 'Old');
    });

    test('== compares values, not references', () {
      final s1 = ItemDetailsState(name: 'A', description: 'B', images: ImageSet.empty());
      final s2 = ItemDetailsState(name: 'A', description: 'B', images: ImageSet.empty());

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
    });

    test('inequality when fields differ', () {
      final imgSet = ImageSet.fromLists(
        ids: [PersistedImageIdentifier('C')],
        refs: [const FileImageRef('/tmp/C')],
      );

      final base = ItemDetailsState(name: 'A', description: 'B', images: imgSet);

      expect(base == base.copyWith(name: 'X'), isFalse);
      expect(base == base.copyWith(description: 'Y'), isFalse);
      expect(base == base.copyWith(images: ImageSet.empty()), isFalse);
    });
  });
}
