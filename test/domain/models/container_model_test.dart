// test/domain/models/item_and_container_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/domain/models/container_model.dart';

void main() {
  test('constructor assigns fields', () {
    final container = Container(
      id: 'C1',
      roomId: 'R1',
      parentContainerId: 'P1',
      name: 'Shelf',
      description: 'Bookshelf',
      imageGuids: ['img1', 'img2'],
      positionIndex: 1,
    );

    expect(container.id, 'C1');
    expect(container.roomId, 'R1');
    expect(container.parentContainerId, 'P1');
    expect(container.name, 'Shelf');
    expect(container.description, 'Bookshelf');
    expect(container.imageGuids, ['img1', 'img2']);
    expect(container.positionIndex, 1);
  });

  test('copyWith creates modified copy without touching original', () {
    final original = Container(roomId: 'R1', name: 'Bin');
    final updated = original.copyWith(name: 'Updated Bin', parentContainerId: 'P1');

    expect(updated.name, 'Updated Bin');
    expect(updated.parentContainerId, 'P1');

    // original unchanged
    expect(original.name, 'Bin');
    expect(original.parentContainerId, isNull);

    // id preserved
    expect(updated.id, original.id);
  });

  test('equality and hashCode are based on id only', () {
    final a = Container(id: 'same', roomId: 'R1', name: 'Shelf');
    final b = Container(id: 'same', roomId: 'R2', name: 'Other');
    final c = Container(id: 'different', roomId: 'R1', name: 'Shelf');

    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    expect(a, isNot(equals(c)));
  });

  test('toString includes type and id', () {
    final c = Container(id: 'C1', roomId: 'R1', name: 'Bin');
    expect(c.toString(), contains('Container'));
    expect(c.toString(), contains('C1'));
  });
}
