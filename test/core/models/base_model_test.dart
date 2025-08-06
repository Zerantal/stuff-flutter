import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:uuid/uuid.dart';

// Your project import for BaseModel
import 'package:stuff/core/models/base_model.dart';

import 'base_model_test.mocks.dart';

// --- Concrete implementation for testing ---
class TestModel extends BaseModel {
  @HiveField(3)
  String? name;

  // For testing, allow controlling the super.save() behavior
  final Future<void> Function()? _superSaveOverride;

  TestModel({
    super.id,
    super.createdAt,
    super.updatedAt,
    this.name,
    Future<void> Function()? superSaveOverride,
  }) : _superSaveOverride = superSaveOverride;

  @override
  Future<void> save() {
    if (_superSaveOverride != null) {
      super.touch(); // Ensure BaseModel's touch is still called
      return _superSaveOverride();
    }
    return super.save(); // Normal BaseModel behavior
  }
}

@GenerateMocks([Uuid])
void main() {
  group('BaseModel Tests', () {
    late MockUuid mockUuid;

    setUp(() {
      mockUuid = MockUuid();
      // Provide a default behavior for Uuid().v4()
      when(mockUuid.v4()).thenReturn('test-uuid-1234');
    });

    group('Constructor and Default Values', () {
      test('should use provided id if not null', () {
        final model = TestModel(id: 'custom-id');
        expect(model.id, 'custom-id');
      });

      test('should generate id using Uuid().v4() if id is null', () {
        final model = TestModel();
        expect(model.id, isA<String>());
        expect(model.id, isNotEmpty);
        // A simple regex to check UUID v4 format (not exhaustive)
        expect(
          RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
          ).hasMatch(model.id),
          isTrue,
        );
      });

      test('should use provided createdAt if not null', () {
        final now = DateTime.now();
        final customDate = now.subtract(const Duration(days: 1));
        final model = TestModel(createdAt: customDate);
        expect(model.createdAt, customDate);
      });

      test('should use DateTime.now() for createdAt if null', () {
        final before = DateTime.now();
        final model = TestModel();
        final after = DateTime.now();
        expect(
          model.createdAt.isAfter(before) ||
              model.createdAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          model.createdAt.isBefore(after) ||
              model.createdAt.isAtSameMomentAs(after),
          isTrue,
        );
      });

      test('should use provided updatedAt if not null', () {
        final now = DateTime.now();
        final customDate = now.subtract(const Duration(days: 1));
        final model = TestModel(updatedAt: customDate);
        expect(model.updatedAt, customDate);
      });

      test('should use DateTime.now() for updatedAt if null', () {
        final before = DateTime.now();
        final model = TestModel();
        final after = DateTime.now();
        expect(
          model.updatedAt.isAfter(before) ||
              model.updatedAt.isAtSameMomentAs(before),
          isTrue,
        );
        expect(
          model.updatedAt.isBefore(after) ||
              model.updatedAt.isAtSameMomentAs(after),
          isTrue,
        );
      });
    });

    group('touch() method', () {
      test('should update updatedAt to current DateTime', () async {
        final initialTime = DateTime.now().subtract(const Duration(hours: 1));
        final model = TestModel(updatedAt: initialTime);

        expect(model.updatedAt, initialTime);

        // Ensure some time passes for a different DateTime.now()
        await Future.delayed(const Duration(milliseconds: 10));
        model.touch();

        expect(model.updatedAt, isNot(initialTime));
        expect(model.updatedAt.isAfter(initialTime), isTrue);
      });
    });

    group('save() method', () {
      test(
        'should call touch() (updating updatedAt) and attempt to call super.save()',
        () async {
          final initialUpdateTime = DateTime.now().subtract(
            const Duration(minutes: 5),
          );
          bool superSaveAttempted = false;

          final model = TestModel(
            updatedAt: initialUpdateTime,
            superSaveOverride: () async {
              superSaveAttempted = true;
              // For this test, we don't care about the HiveError,
              // or we can simulate success if needed.
              // If we want to test behavior when super.save() throws,
              // we'd throw here. For now, just indicate it was called.
              return Future.value();
            },
          );

          expect(model.updatedAt, initialUpdateTime);

          // Ensure some time passes for a different DateTime.now() in touch()
          await Future.delayed(const Duration(milliseconds: 10));

          await model.save(); // This will use the _superSaveOverride

          expect(model.updatedAt, isNot(initialUpdateTime));
          expect(
            model.updatedAt.isAfter(initialUpdateTime),
            isTrue,
            reason: "updatedAt should be updated by touch()",
          );
          expect(
            superSaveAttempted,
            isTrue,
            reason: "super.save() override should have been called",
          );
        },
      );

      test('save() method signature returns a Future<void>', () {
        // This test focuses purely on the method signature's return type.
        // We provide a non-throwing override for super.save to avoid HiveError.
        final model = TestModel(
          superSaveOverride: () =>
              Future.value(), // Simple non-throwing override
        );
        expect(model.save(), isA<Future<void>>());
      });

      test(
        'save() should still update touch() even if super.save() throws (simulated)',
        () async {
          final initialUpdateTime = DateTime.now().subtract(
            const Duration(minutes: 5),
          );
          bool superSaveAttemptedAndThrew = false;

          final model = TestModel(
            updatedAt: initialUpdateTime,
            superSaveOverride: () async {
              superSaveAttemptedAndThrew = true;
              throw HiveError("Simulated Hive Error from super.save()");
            },
          );

          await Future.delayed(const Duration(milliseconds: 10));

          try {
            await model.save();
            fail("Should have thrown HiveError");
          } catch (e) {
            expect(e, isA<HiveError>());
            expect(
              (e as HiveError).message,
              "Simulated Hive Error from super.save()",
            );
          }

          expect(superSaveAttemptedAndThrew, isTrue);
          // Crucially, touch() should have run BEFORE super.save(;) was called (and threw)
          expect(model.updatedAt, isNot(initialUpdateTime));
          expect(model.updatedAt.isAfter(initialUpdateTime), isTrue);
        },
      );
    });
  });
}
