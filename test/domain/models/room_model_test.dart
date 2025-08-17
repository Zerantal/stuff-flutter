// test/domain/models/room_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/domain/models/room_model.dart';

void main() {
  group('Room Model', () {
    group('Constructor and Default Values (including BaseModel behavior)', () {
      test('correctly initializes all fields when all are provided', () {
        // Arrange
        final imageGuids = ['img1.jpg', 'img2.jpg'];
        const testId = 'room_id_123';
        final created = DateTime(2023, 1, 1, 10, 0, 0);
        final updated = DateTime(2023, 1, 1, 12, 0, 0);

        // Act
        final room = Room(
          id: testId,
          locationId: 'L1',
          name: 'Kitchen',
          description: 'Downstairs kitchen',
          imageGuids: imageGuids,
          createdAt: created,
          updatedAt: updated,
        );

        // Assert
        expect(room.id, testId);
        expect(room.createdAt, created);
        expect(room.updatedAt, updated);

        expect(room.locationId, 'L1');
        expect(room.name, 'Kitchen');
        expect(room.description, 'Downstairs kitchen');
        expect(room.imageGuids, equals(imageGuids));
      });

      test('imageGuids defaults to empty list if null or omitted', () {
        final a = Room(locationId: 'L1', name: 'Office', imageGuids: null);
        final b = Room(locationId: 'L1', name: 'Office');

        expect(a.imageGuids, isEmpty);
        expect(b.imageGuids, isEmpty);
      });

      test('imageGuids is unmodifiable', () {
        final room = Room(locationId: 'L1', name: 'Garage', imageGuids: ['a']);
        expect(() => room.imageGuids.add('b'), throwsUnsupportedError);
      });
    });

    group('copyWith', () {
      test('updates provided fields and preserves others', () {
        final original = Room(
          id: 'fixed_id',
          locationId: 'L1',
          name: 'Bedroom',
          description: 'Master',
          imageGuids: ['x', 'y'],
          createdAt: DateTime(2024, 1, 1, 9),
          updatedAt: DateTime(2024, 1, 1, 10),
        );

        final copy = original.copyWith(
          name: 'Guest Bedroom',
          description: 'Upstairs guest',
          imageGuids: ['a', 'b', 'c'],
        );

        // BaseModel preserved
        expect(copy.id, original.id);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);

        // Changed fields
        expect(copy.name, 'Guest Bedroom');
        expect(copy.description, 'Upstairs guest');
        expect(copy.imageGuids, ['a', 'b', 'c']);

        // Unchanged fields
        expect(copy.locationId, 'L1');
      });

      test('clones provided imageGuids and remains unmodifiable', () {
        final original = Room(locationId: 'L1', name: 'Den');
        final external = <String>['one', 'two'];

        final copy = original.copyWith(imageGuids: external);

        // Mutate the external list; Room should not reflect it if cloning is correct
        external.add('three');
        expect(copy.imageGuids, ['one', 'two']);
        expect(() => copy.imageGuids.add('four'), throwsUnsupportedError);
      });

      test('when imageGuids not provided, copy keeps same contents and is independent', () {
        final original = Room(locationId: 'L1', name: 'Library', imageGuids: ['a']);
        final copy = original.copyWith();

        expect(copy.imageGuids, ['a']);
        expect(() => copy.imageGuids.add('b'), throwsUnsupportedError);
      });

      test('REGRESSION: omitting locationId should preserve original locationId', () {
        final original = Room(locationId: 'L-KEEP', name: 'Kitchen');
        final copy = original.copyWith(); // no locationId supplied

        // If copyWith mistakenly uses this.name, this will fail.
        expect(copy.locationId, 'L-KEEP');
      });
    });
  });
}
