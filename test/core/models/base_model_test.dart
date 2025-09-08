// test/core/models/base_model_test.dart
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/core/models/base_model.dart';

/// Simple concrete subclass so we can instantiate BaseModel in tests.
class _TestModel extends BaseModel<_TestModel> {
  final String? name;
  _TestModel({super.id, super.createdAt, super.updatedAt, this.name});

  @override
  _TestModel copyWithUpdatedAt(DateTime updatedAt) {
    return _TestModel(id: id, createdAt: createdAt, updatedAt: updatedAt, name: name);
  }
}

class _TestModel2 extends BaseModel<_TestModel2> {
  final String? name;
  _TestModel2({super.id, super.createdAt, super.updatedAt, this.name});

  @override
  _TestModel2 copyWithUpdatedAt(DateTime updatedAt) {
    return _TestModel2(id: id, createdAt: createdAt, updatedAt: updatedAt, name: name);
  }
}

void main() {
  group('BaseModel constructor', () {
    test('generates id and timestamps by default', () {
      final m = _TestModel();

      // Non-empty UUID v4 format: xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx
      final uuidV4 = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(m.id, isNotEmpty);
      expect(uuidV4.hasMatch(m.id), isTrue);

      expect(m.createdAt, isA<DateTime>());
      expect(m.updatedAt, isA<DateTime>());

      // updatedAt should not be before createdAt (can be equal if same tick)
      expect(m.updatedAt.isBefore(m.createdAt), isFalse);
    });

    test('respects provided id and timestamps', () {
      final created = DateTime.utc(2020, 1, 1, 12, 0, 0);
      final updated = DateTime.utc(2020, 1, 2, 12, 0, 0);
      final m = _TestModel(id: 'custom-id', createdAt: created, updatedAt: updated);

      expect(m.id, 'custom-id');
      expect(m.createdAt, created);
      expect(m.updatedAt, updated);
    });
  });

  group('BaseModel.withTouched', () {
    test('bumps updatedAt when clock is after createdAt', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final later = DateTime.utc(2022, 1, 1, 11, 0, 0);

      final m = withClock(Clock.fixed(created), () {
        return _TestModel();
      });

      final touched = withClock(Clock.fixed(later), () {
        return m.withTouched();
      });

      expect(touched.createdAt, created);
      expect(touched.updatedAt, later);
      expect(m.updatedAt, created); // original unchanged
    });

    test('clamps updatedAt to createdAt if clock is before createdAt', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final earlier = DateTime.utc(2022, 1, 1, 9, 0, 0);

      final m = withClock(Clock.fixed(created), () {
        return _TestModel();
      });

      final touched = withClock(Clock.fixed(earlier), () {
        return m.withTouched();
      });

      // Because BaseModel ensures updatedAt is never before createdAt
      expect(touched.createdAt, created);
      expect(touched.updatedAt, created);
    });

    test('multiple touches advance updatedAt monotonically', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final mid = DateTime.utc(2022, 1, 1, 10, 5, 0);
      final later = DateTime.utc(2022, 1, 1, 10, 10, 0);

      final item = withClock(Clock.fixed(created), () {
        return _TestModel();
      });

      final touched1 = withClock(Clock.fixed(mid), () {
        return item.withTouched();
      });
      final touched2 = withClock(Clock.fixed(later), () {
        return touched1.withTouched();
      });

      expect(touched1.updatedAt, mid);
      expect(touched2.updatedAt, later);
    });
  });

  group('BaseModel equality & hashCode', () {
    test('objects with same id and type are equal', () {
      final a = _TestModel(id: 'X', name: 'A');
      final b = _TestModel(id: 'X', name: 'B');

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('objects with same id but different type are not equal', () {
      final a = _TestModel(id: 'X', name: 'A');
      final c = _TestModel2(id: 'X', name: 'C');

      expect(a, isNot(equals(c)));
    });

    test('objects with different ids are not equal', () {
      final a = _TestModel(id: 'X', name: 'A');
      final b = _TestModel(id: 'Y', name: 'A');

      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('toString includes runtimeType and id', () {
      final m = _TestModel(id: 'I123', name: 'Thing');
      expect(m.toString(), contains('TestModel'));
      expect(m.toString(), contains('I123'));
    });
  });

  group('BaseModel._normalizeUpdated (via constructor)', () {
    test('uses createdAt when updatedAt < createdAt', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final badUpdated = DateTime.utc(2022, 1, 1, 9, 0, 0);

      final m = _TestModel(
        id: 'X',
        name: 'Test',
        createdAt: created,
        updatedAt: badUpdated, // should be clamped
      );

      expect(m.createdAt, created);
      expect(m.updatedAt, created);
    });

    test('uses provided updatedAt when >= createdAt', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final goodUpdated = DateTime.utc(2022, 1, 1, 11, 0, 0);

      final m = _TestModel(id: 'Y', name: 'Crate', createdAt: created, updatedAt: goodUpdated);

      expect(m.createdAt, created);
      expect(m.updatedAt, goodUpdated);
    });

    test('defaults updatedAt to now if null', () {
      final created = DateTime.utc(2022, 1, 1, 10, 0, 0);
      final now = DateTime.utc(2022, 1, 1, 10, 5, 0);

      final m = withClock(Clock.fixed(now), () {
        return _TestModel(id: 'Z', name: 'Chair', createdAt: created, updatedAt: null);
      });

      expect(m.createdAt, created);
      expect(m.updatedAt, now);
    });
  });
}
