// test/features/location/widgets/grid_location_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/features/location/widgets/grid_location_card.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/image/image_ref.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('GridLocationCard taps call onView with same instance', (tester) async {
    final loc = Location(name: 'Lounge');
    Location? tapped;

    await tester.pumpWidget(
      wrap(
        GridLocationCard(
          location: loc,
          images: const <ImageRef>[],
          onView: (l) => tapped = l,
          onEdit: (_) {},
          onDelete: (_) {},
        ),
      ),
    );

    // Tap the card InkWell
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(identical(tapped, loc), isTrue);
  });

  testWidgets('GridLocationCard menu triggers edit/view/delete', (tester) async {
    final loc = Location(name: 'Office');
    String last = '';

    await tester.pumpWidget(
      wrap(
        GridLocationCard(
          location: loc,
          images: const <ImageRef>[],
          onView: (_) => last = 'view',
          onEdit: (_) => last = 'edit',
          onDelete: (_) => last = 'delete',
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(last, 'edit');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(last, 'view');

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(last, 'delete');
  });
}
