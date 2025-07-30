import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/models/location_model.dart';

void main() {
  group('Location Model', () {
    group('Constructor and Default Values', () {
      test('should correctly initialize all fields when all are provided', () {
        // Arrange
        final imageGuids = ['guid1.jpg', 'guid2.jpg'];

        // Act
        final location = Location(
          id: 'test_id',
          name: 'Test Location',
          description: 'A description',
          address: '123 Test St',
          imageGuids: imageGuids,
        );

        // Assert
        expect(location.id, 'test_id');
        expect(location.name, 'Test Location');
        expect(location.description, 'A description');
        expect(location.address, '123 Test St');
        expect(location.imageGuids, equals(imageGuids));
        // Ensure imageGuids is a new list instance if it was passed, not a reference (though your constructor logic already handles this for null)
        // For non-null passed lists, Dart usually assigns the reference, which is fine here.
      });

      test(
        'imageGuids should default to an empty list if null is passed to constructor',
        () {
          // Act
          final location = Location(
            id: 'test_id_2',
            name: 'No Images Location',
            imageGuids: null,
          );

          // Assert
          expect(location.imageGuids, isNotNull);
          expect(location.imageGuids, isEmpty);
        },
      );

      test(
        'imageGuids should default to an empty list if not provided in constructor',
        () {
          // Act
          final location = Location(
            id: 'test_id_3',
            name: 'Implicit No Images Location',
          );
          // Assert
          expect(location.imageGuids, isNotNull);
          expect(location.imageGuids, isEmpty);
        },
      );
    });

    group('copyWith Method', () {
      late Location initialLocation;
      final initialImageGuids = ['initial1.jpg', 'initial2.jpg'];

      setUp(() {
        initialLocation = Location(
          id: 'original_id',
          name: 'Original Name',
          description: 'Original Description',
          address: 'Original Address',
          imageGuids: List.from(initialImageGuids), // Use a copy for setup
        );
      });

      test('should create a new instance, not modify the original', () {
        // Act
        final copiedLocation = initialLocation.copyWith();

        // Assert
        expect(copiedLocation, isNot(same(initialLocation)));
      });

      test(
        'should copy all values if no arguments are provided to copyWith',
        () {
          // Act
          final copiedLocation = initialLocation.copyWith();

          // Assert
          expect(copiedLocation.id, initialLocation.id);
          expect(copiedLocation.name, initialLocation.name);
          expect(copiedLocation.description, initialLocation.description);
          expect(copiedLocation.address, initialLocation.address);
          expect(copiedLocation.imageGuids, equals(initialLocation.imageGuids));
          // Also check if the list is a new instance
          expect(
            copiedLocation.imageGuids,
            isNot(same(initialLocation.imageGuids)),
          );
        },
      );

      test('should update only the name when only name is provided', () {
        // Act
        final copiedLocation = initialLocation.copyWith(name: 'Updated Name');

        // Assert
        expect(copiedLocation.id, initialLocation.id);
        expect(copiedLocation.name, 'Updated Name');
        expect(copiedLocation.description, initialLocation.description);
        expect(copiedLocation.address, initialLocation.address);
        expect(copiedLocation.imageGuids, equals(initialLocation.imageGuids));
      });

      test(
        'should update only the description when only description is provided',
        () {
          // Act
          final copiedLocation = initialLocation.copyWith(
            description: 'Updated Description',
          );

          // Assert
          expect(copiedLocation.name, initialLocation.name);
          expect(copiedLocation.description, 'Updated Description');
        },
      );

      test('should update only the address when only address is provided', () {
        // Act
        final copiedLocation = initialLocation.copyWith(
          address: 'Updated Address',
        );

        // Assert
        expect(copiedLocation.name, initialLocation.name);
        expect(copiedLocation.address, 'Updated Address');
      });

      test('should update imageGuids when a new list is provided', () {
        // Arrange
        final newImageGuids = ['new1.jpg', 'new2.jpg', 'new3.jpg'];

        // Act
        final copiedLocation = initialLocation.copyWith(
          imageGuids: newImageGuids,
        );

        // Assert
        expect(copiedLocation.imageGuids, equals(newImageGuids));
        // Ensure it's a new instance if provided
        expect(
          copiedLocation.imageGuids,
          isNot(same(newImageGuids)),
        ); // Because your copyWith creates a new List.from()
      });

      test(
        'copyWith should handle null imageGuids by taking from original',
        () {
          // Arrange
          final locationWithNullGuids = Location(
            id: 'id1',
            name: 'Name1',
            imageGuids: null,
          );

          // Act
          final copiedLocation = locationWithNullGuids
              .copyWith(); // No imageGuids passed to copyWith

          // Assert
          expect(copiedLocation.imageGuids, isNotNull);
          expect(
            copiedLocation.imageGuids,
            isEmpty,
          ); // Because original defaulted to []
        },
      );

      test(
        'copyWith should copy original imageGuids if imageGuids param is not provided',
        () {
          // Act
          final copiedLocation = initialLocation
              .copyWith(); // No imageGuids passed to copyWith

          // Assert
          expect(copiedLocation.imageGuids, equals(initialLocation.imageGuids));
          expect(
            copiedLocation.imageGuids,
            isNot(same(initialLocation.imageGuids)),
          );
        },
      );

      test(
        'copyWith correctly handles complex imageGuids logic from constructor and copyWith',
        () {
          // Original has images
          Location loc1 = Location(
            id: '1',
            name: 'N1',
            imageGuids: ['a.jpg', 'b.jpg'],
          );
          Location loc1CopiedNoChange = loc1.copyWith();
          expect(loc1CopiedNoChange.imageGuids, equals(['a.jpg', 'b.jpg']));
          expect(loc1CopiedNoChange.imageGuids, isNot(same(loc1.imageGuids)));

          // Original has images, copyWith provides new images
          Location loc1CopiedWithNew = loc1.copyWith(imageGuids: ['c.jpg']);
          expect(loc1CopiedWithNew.imageGuids, equals(['c.jpg']));

          // Original has no images (defaulted to empty list)
          Location loc2 = Location(id: '2', name: 'N2'); // imageGuids is []
          Location loc2CopiedNoChange = loc2.copyWith();
          expect(loc2CopiedNoChange.imageGuids, isEmpty);

          // Original has no images, copyWith provides new images
          Location loc2CopiedWithNew = loc2.copyWith(imageGuids: ['d.jpg']);
          expect(loc2CopiedWithNew.imageGuids, equals(['d.jpg']));

          // Original has null images (defaulted to empty list)
          Location loc3 = Location(
            id: '3',
            name: 'N3',
            imageGuids: null,
          ); // imageGuids is []
          Location loc3CopiedNoChange = loc3.copyWith();
          expect(loc3CopiedNoChange.imageGuids, isEmpty);
        },
      );
    });
  });
}
