import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/context_action_menu.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

Future<void> _openMenu(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('context_action_menu')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows no menu items when no callbacks are provided', (tester) async {
    await tester.pumpWidget(
      _wrap(const ContextActionMenu(onEdit: null, onView: null, onDelete: null)),
    );

    await _openMenu(tester);

    expect(find.byKey(const ValueKey('edit_btn')), findsNothing);
    expect(find.byKey(const ValueKey('view_btn')), findsNothing);
    expect(find.byKey(const ValueKey('delete_btn')), findsNothing);

    expect(find.text('Edit'), findsNothing);
    expect(find.text('View'), findsNothing);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('selecting Edit calls onEdit only', (tester) async {
    var editCount = 0;
    var viewCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      _wrap(
        ContextActionMenu(
          onEdit: () => editCount++,
          onView: () => viewCount++,
          onDelete: () => deleteCount++,
        ),
      ),
    );

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('edit_btn')));
    await tester.pumpAndSettle();

    expect(editCount, 1);
    expect(viewCount, 0);
    expect(deleteCount, 0);
  });

  testWidgets('selecting Open calls onView only', (tester) async {
    var editCount = 0;
    var viewCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      _wrap(
        ContextActionMenu(
          onEdit: () => editCount++,
          onView: () => viewCount++,
          onDelete: () => deleteCount++,
        ),
      ),
    );

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('view_btn')));
    await tester.pumpAndSettle();

    expect(editCount, 0);
    expect(viewCount, 1);
    expect(deleteCount, 0);
  });

  testWidgets('selecting Delete calls onDelete only', (tester) async {
    var editCount = 0;
    var viewCount = 0;
    var deleteCount = 0;

    await tester.pumpWidget(
      _wrap(
        ContextActionMenu(
          onEdit: () => editCount++,
          onView: () => viewCount++,
          onDelete: () => deleteCount++,
        ),
      ),
    );

    await _openMenu(tester);
    await tester.tap(find.byKey(const ValueKey('delete_btn')));
    await tester.pumpAndSettle();

    expect(editCount, 0);
    expect(viewCount, 0);
    expect(deleteCount, 1);
  });
}
