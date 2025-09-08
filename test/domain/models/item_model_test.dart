// test/domain/models/item_and_container_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/domain/models/item_model.dart';

void main() {
  test('constructor assigns fields', () {
    final item = Item(
      id: 'I1',
      roomId: 'R1',
      containerId: 'C1',
      name: 'Laptop',
      description: 'Work machine',
      attrs: {'brand': 'Dell'},
      imageGuids: ['img1'],
      positionIndex: 3,
      isArchived: true,
    );

    expect(item.id, 'I1');
    expect(item.roomId, 'R1');
    expect(item.containerId, 'C1');
    expect(item.name, 'Laptop');
    expect(item.description, 'Work machine');
    expect(item.attrs['brand'], 'Dell');
    expect(item.imageGuids, ['img1']);
    expect(item.positionIndex, 3);
    expect(item.isArchived, true);
  });

  test('copyWith creates modified copy without touching original', () {
    final original = Item(roomId: 'R1', name: 'Box');
    final updated = original.copyWith(name: 'Updated Box', isArchived: true);

    expect(updated.name, 'Updated Box');
    expect(updated.isArchived, true);

    // original unchanged
    expect(original.name, 'Box');
    expect(original.isArchived, false);

    // id preserved
    expect(updated.id, original.id);
  });

  test('equality and hashCode are based on id only', () {
    final a = Item(id: 'same', roomId: 'R1', name: 'Box');
    final b = Item(id: 'same', roomId: 'R2', name: 'Different');
    final c = Item(id: 'different', roomId: 'R1', name: 'Box');

    expect(a, equals(b)); // same id
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c))); // different id
  });

  test('toString includes type and id', () {
    final item = Item(id: 'I1', roomId: 'R1', name: 'Thing');
    expect(item.toString(), contains('Item'));
    expect(item.toString(), contains('I1'));
  });
}
