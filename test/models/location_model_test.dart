import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/models/location_model.dart';

void main() {
  group('Location Model', () {
    group('Constructor and Default Values (including BaseModel behavior)', () {
      test(
        'should correctly initialize all specific Location fields when all are provided',
        () {
          // Arrange
          final imageGuids = ['guid1.jpg', 'guid2.jpg'];
          const testId = 'test_id_provided';
          final specificCreatedAt = DateTime(2023, 1, 1, 10, 0, 0);
          final specificUpdatedAt = DateTime(2023, 1, 1, 12, 0, 0);

          // Act
          final location = Location(
            id: testId, // Explicitly provide ID
            name: 'Test Location',
            description: 'A description',
            address: '123 Test St',
            imageGuids: imageGuids,
            createdAt: specificCreatedAt, // Explicitly provide createdAt
            updatedAt: specificUpdatedAt, // Explicitly provide updatedAt
          );

          // Assert
          // BaseModel fields
          expect(location.id, testId);
          expect(location.createdAt, specificCreatedAt);
          expect(location.updatedAt, specificUpdatedAt);

          // Location specific fields
          expect(location.name, 'Test Location');
          expect(location.description, 'A description');
          expect(location.address, '123 Test St');
          expect(location.imageGuids, equals(imageGuids));
        },
      );

      test('id should be a non-null UUID string if not provided', () {
        // Act
        final location = Location(name: 'Test Location with auto ID');

        // Assert
        expect(location.id, isNotNull);
        expect(location.id, isA<String>());
        expect(location.id.length, greaterThan(30)); // Basic UUID length check
        // For a more robust check, you could try Uuid.isValidUUID(fromString: location.id)
        // if Uuid package is used and you want to be very specific.
      });

      test(
        'createdAt and updatedAt should be recent DateTime if not provided, and updatedAt should equal createdAt on new instance',
        () {
          // Arrange
          final beforeCreation = DateTime.now();

          // Act
          final location = Location(name: 'Test Location with auto timestamps');

          // Assert
          final afterCreation = DateTime.now();

          expect(location.createdAt, isNotNull);
          expect(location.createdAt, isA<DateTime>());
          expect(
            location.createdAt.isAfter(beforeCreation) ||
                location.createdAt.isAtSameMomentAs(beforeCreation),
            isTrue,
          );
          expect(
            location.createdAt.isBefore(afterCreation) ||
                location.createdAt.isAtSameMomentAs(afterCreation),
            isTrue,
          );

          expect(location.updatedAt, isNotNull);
          expect(
            location.updatedAt,
            location.createdAt,
            reason: "On new instance, updatedAt should equal createdAt",
          );
        },
      );

      test(
        'imageGuids should default to an empty list if null is passed to constructor',
        () {
          // Act
          final location = Location(
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
            name: 'Implicit No Images Location',
            // imageGuids is not provided
          );
          // Assert
          expect(location.imageGuids, isNotNull);
          expect(location.imageGuids, isEmpty);
        },
      );

      test(
        'all optional fields (description, address, imageGuids) should be settable and retrievable',
        () {
          // Arrange
          final imgGuids = ['img1.png'];
          // Act
          final locationFull = Location(
            name: 'Full Location',
            description: 'Full Desc',
            address: 'Full Address',
            imageGuids: imgGuids,
          );
          final locationMinimal = Location(name: 'Minimal Location');

          // Assert
          expect(locationFull.description, 'Full Desc');
          expect(locationFull.address, 'Full Address');
          expect(locationFull.imageGuids, imgGuids);

          expect(locationMinimal.description, isNull);
          expect(locationMinimal.address, isNull);
          expect(locationMinimal.imageGuids, isEmpty); // Defaults to empty list
        },
      );
    });
  });
}
