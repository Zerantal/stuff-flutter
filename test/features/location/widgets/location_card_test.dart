// test/features/location/widgets/location_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/features/location/widgets/location_card.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/image/image_ref.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('LocationCard taps call onView with same instance', (tester) async {
    final loc = Location(name: 'Kitchen');
    Location? tapped;
    final widget = LocationCard(
      location: loc,
      images: const <ImageRef>[],
      onView: (l) => tapped = l,
      onEdit: (_) {},
      onDelete: (_) {},
    );

    await tester.pumpWidget(wrap(widget));
    // Tap the card InkWell
    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    expect(identical(tapped, loc), isTrue);
  });

  testWidgets('LocationCard menu triggers edit/view/delete callbacks', (tester) async {
    final loc = Location(name: 'Study');
    String last = '';

    await tester.pumpWidget(
      wrap(
        LocationCard(
          location: loc,
          images: const <ImageRef>[],
          onView: (_) => last = 'view',
          onEdit: (_) => last = 'edit',
          onDelete: (_) => last = 'delete',
        ),
      ),
    );

    // Open menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    // Tap Edit
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(last, 'edit');

    // Re-open and tap Open
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(last, 'view');

    // Re-open and tap Delete
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(last, 'delete');
  });
}
