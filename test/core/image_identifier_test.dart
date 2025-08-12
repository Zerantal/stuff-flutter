import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stuff/core/image_identifier.dart';

class MockFile extends Mock implements File {
  String _path = '';

  @override
  String get path => _path;

  // Method to set the path for the mock file in tests
  void setMockPath(String path) {
    _path = path;
  }
}

void main() {
  group('GuidIdentifier', () {
    test('Constructor should initialize guid correctly', () {
      const testGuid = 'test_guid.jpg';
      final identifier = GuidIdentifier(testGuid);
      expect(identifier.guid, equals(testGuid));
    });

    group('Equality (==)', () {
      final identifier1 = GuidIdentifier('guid1.jpg');
      final identifier1Copy = GuidIdentifier('guid1.jpg');
      final identifier2 = GuidIdentifier('guid2.png');

      test('should be equal to itself', () {
        expect(identifier1 == identifier1, isTrue);
      });

      test('should be equal to another instance with the same guid', () {
        expect(identifier1 == identifier1Copy, isTrue);
      });

      test('should not be equal to an instance with a different guid', () {
        expect(identifier1 == identifier2, isFalse);
      });

      test('should not be equal to an object of a different type', () {
        // ignore: unrelated_type_equality_checks
        expect(identifier1 == 'guid1.jpg', isFalse);
      });
    });

    group('hashCode', () {
      test('should return the same hashCode for equal objects', () {
        final identifier1 = GuidIdentifier('guid1.jpg');
        final identifier1Copy = GuidIdentifier('guid1.jpg');
        expect(identifier1.hashCode, equals(identifier1Copy.hashCode));
      });

      test(
        'should ideally return different hashCodes for different objects (though not guaranteed)',
        () {
          // This is not a strict requirement of hashCode but good for hash map performance.
          // It's mainly testing that it's derived from the guid.
          final identifier1 = GuidIdentifier('guid1.jpg');
          final identifier2 = GuidIdentifier('guid2.png');
          if (identifier1.guid.hashCode != identifier2.guid.hashCode) {
            // Check if underlying hash codes are different
            expect(identifier1.hashCode, isNot(equals(identifier2.hashCode)));
          }
        },
      );

      test('hashCode should be based on guid', () {
        const guid = 'my_guid.png';
        final identifier = GuidIdentifier(guid);
        expect(identifier.hashCode, equals(guid.hashCode));
      });
    });
  });

  group('TempFileIdentifier', () {
    late MockFile mockFile1;
    late MockFile mockFile1DuplicatePath;
    late MockFile mockFile2;

    setUp(() {
      mockFile1 = MockFile();
      mockFile1DuplicatePath = MockFile();
      mockFile2 = MockFile();

      // Set paths for mocks
      // It's important that the path is what's being compared in your TempFileIdentifier's == and hashCode
      mockFile1.setMockPath('/fake/path/to/image1.jpg');
      mockFile1DuplicatePath.setMockPath('/fake/path/to/image1.jpg'); // Same path as mockFile1
      mockFile2.setMockPath('/fake/path/to/image2.png'); // Different path
    });

    test('Constructor should initialize file correctly', () {
      final identifier = TempFileIdentifier(mockFile1);
      expect(identifier.file, equals(mockFile1));
    });

    group('Equality (==)', () {
      test('should be equal to itself', () {
        final identifier = TempFileIdentifier(mockFile1);
        expect(identifier == identifier, isTrue);
      });

      test('should be equal to another instance with a file having the same path', () {
        final identifier1 = TempFileIdentifier(mockFile1);
        final identifier1PathCopy = TempFileIdentifier(mockFile1DuplicatePath);
        // Note: They are equal because their file.path is the same,
        // even if mockFile1 and mockFile1DuplicatePath are different MockFile instances.
        expect(identifier1 == identifier1PathCopy, isTrue);
      });

      test('should not be equal to an instance with a file having a different path', () {
        final identifier1 = TempFileIdentifier(mockFile1);
        final identifier2 = TempFileIdentifier(mockFile2);
        expect(identifier1 == identifier2, isFalse);
      });

      test('should not be equal to an object of a different type', () {
        final identifier = TempFileIdentifier(mockFile1);
        // ignore: unrelated_type_equality_checks
        expect(identifier == mockFile1, isFalse);
      });
    });

    group('hashCode', () {
      test('should return the same hashCode for objects with files having the same path', () {
        final identifier1 = TempFileIdentifier(mockFile1);
        final identifier1PathCopy = TempFileIdentifier(mockFile1DuplicatePath);
        expect(identifier1.hashCode, equals(identifier1PathCopy.hashCode));
      });

      test(
        'should ideally return different hashCodes for objects with files having different paths',
        () {
          final identifier1 = TempFileIdentifier(mockFile1);
          final identifier2 = TempFileIdentifier(mockFile2);
          if (mockFile1.path.hashCode != mockFile2.path.hashCode) {
            expect(identifier1.hashCode, isNot(equals(identifier2.hashCode)));
          }
        },
      );

      test('hashCode should be based on file.path', () {
        final path = '/fake/path/image.tmp';
        mockFile1.setMockPath(path);
        final identifier = TempFileIdentifier(mockFile1);
        expect(identifier.hashCode, equals(path.hashCode));
      });
    });
  });
}
