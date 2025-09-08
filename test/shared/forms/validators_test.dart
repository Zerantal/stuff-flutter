// test/shared/forms/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/shared/forms/validators.dart';

void main() {
  group('requiredMax', () {
    for (final max in [1, 5, 10]) {
      test('max=$max validates correctly', () {
        final validator = requiredMax(max);

        // Empty / null => Required
        expect(validator(null), 'Required');
        expect(validator(''), 'Required');
        expect(validator('   '), 'Required');

        // Valid inputs (length <= max)
        expect(validator('a' * max), isNull);
        if (max > 1) {
          expect(validator('a' * (max - 1)), isNull);
        }

        // Invalid input (length > max)
        expect(validator('a' * (max + 1)), 'Keep it under $max characters');
      });
    }
  });

  group('optionalMax', () {
    for (final max in [1, 5, 10]) {
      test('max=$max validates correctly', () {
        final validator = optionalMax(max);

        // Empty / null => no error
        expect(validator(null), isNull);
        expect(validator(''), isNull);
        expect(validator('   '), isNull);

        // Valid inputs (length <= max)
        expect(validator('a' * max), isNull);
        if (max > 1) {
          expect(validator('a' * (max - 1)), isNull);
        }

        // Invalid input (length > max)
        expect(validator('a' * (max + 1)), 'Keep it under $max characters');
      });
    }
  });
}
