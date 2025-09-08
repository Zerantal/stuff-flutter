// test/shared/widgets/empty_list_state_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/empty_list_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders text and button label', (tester) async {
    await tester.pumpWidget(
      _wrap(
        EmptyListState(
          text: 'Nothing here yet',
          buttonText: 'Add item',
          buttonIcon: const Icon(Icons.add),
          onAdd: () {},
        ),
      ),
    );

    expect(find.text('Nothing here yet'), findsOneWidget);
    expect(find.text('Add item'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('tapping button calls onAdd', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _wrap(
        EmptyListState(
          text: 'Empty',
          buttonText: 'Create',
          buttonIcon: const Icon(Icons.add_circle_outline),
          onAdd: () => tapped++,
        ),
      ),
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
  });

  testWidgets('Test absence of icon', (tester) async {
    await tester.pumpWidget(
      _wrap(EmptyListState(text: 'Empty', buttonText: 'Create', onAdd: () => {})),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Icon), findsNothing);
  });
}
