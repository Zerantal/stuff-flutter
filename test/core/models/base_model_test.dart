// test/core/models/base_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/core/models/base_model.dart';

/// Simple concrete subclass so we can instantiate BaseModel in tests.
class _TestModel extends BaseModel {
  _TestModel({super.id, super.createdAt, super.updatedAt});
}

void main() {
  group('BaseModel', () {
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

    test('touch() bumps updatedAt', () async {
      final m = _TestModel();
      final before = m.updatedAt;

      // Give the clock a tiny nudge to avoid same-moment equality on fast machines.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      m.touch();

      expect(m.updatedAt.isAfter(before), isTrue);
    });

    test('generates unique ids per instance', () {
      final a = _TestModel();
      final b = _TestModel();
      expect(a.id, isNot(equals(b.id)));
    });
  });
}
