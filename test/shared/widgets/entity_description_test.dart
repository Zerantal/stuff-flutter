// test/shared/widgets/entity_description_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/app/theme.dart';

import 'package:stuff/shared/widgets/entity_description.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title only when subtitle and badges are null', (tester) async {
    await tester.pumpWidget(_wrap(const EntityDescription(title: 'Kitchen')));

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Upstairs'), findsNothing); // no subtitle
    expect(find.byType(Wrap), findsNothing); // no badges container
  });

  testWidgets('renders non-empty description with top padding of xs', (tester) async {
    await tester.pumpWidget(
      _wrap(const EntityDescription(title: 'Kitchen', description: 'Upstairs')),
    );

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Upstairs'), findsOneWidget);

    // The description Text is wrapped in a Padding with top: 2
    final paddingWithDescription = tester.widget<Padding>(
      find.ancestor(of: find.text('Upstairs'), matching: find.byType(Padding)).first,
    );
    expect(paddingWithDescription.padding is EdgeInsets, true);
    final e = paddingWithDescription.padding as EdgeInsets;
    expect(e.top, AppSpacing.xs);
  });

  testWidgets('empty subtitle string is not rendered', (tester) async {
    await tester.pumpWidget(_wrap(const EntityDescription(title: 'Kitchen', description: '')));
    expect(find.text('Kitchen'), findsOneWidget);
    // No subtitle rendered when empty
    expect(find.text(''), findsNothing);
  });
}
