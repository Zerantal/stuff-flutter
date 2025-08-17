// test/features/location/widgets/location_action_menu_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/features/location/widgets/location_action_menu.dart';
import 'package:stuff/domain/models/location_model.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('LocationActionsMenu triggers onEdit/onView/onDelete with location', (tester) async {
    final loc = Location(name: 'Garage');
    String last = '';
    Location? passed;

    await tester.pumpWidget(
      wrap(
        LocationActionsMenu(
          location: loc,
          onEdit: (l) {
            last = 'edit';
            passed = l;
          },
          onView: (l) {
            last = 'view';
            passed = l;
          },
          onDelete: (l) {
            last = 'delete';
            passed = l;
          },
        ),
      ),
    );

    // Open popup
    await tester.tap(find.byType(PopupMenuButton<LocationAction>));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(last, 'edit');
    expect(identical(passed, loc), isTrue);

    await tester.tap(find.byType(PopupMenuButton<LocationAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(last, 'view');
    expect(identical(passed, loc), isTrue);

    await tester.tap(find.byType(PopupMenuButton<LocationAction>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(last, 'delete');
    expect(identical(passed, loc), isTrue);
  });
}
