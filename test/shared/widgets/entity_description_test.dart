// test/shared/widgets/entity_description_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/entity_description.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders title only when subtitle and badges are null', (tester) async {
    await tester.pumpWidget(_wrap(const EntityDescription(title: 'Kitchen')));

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Upstairs'), findsNothing); // no subtitle
    expect(find.byType(Wrap), findsNothing); // no badges container
  });

  testWidgets('renders non-empty subtitle with top padding of 2', (tester) async {
    await tester.pumpWidget(_wrap(const EntityDescription(title: 'Kitchen', subtitle: 'Upstairs')));

    expect(find.text('Kitchen'), findsOneWidget);
    expect(find.text('Upstairs'), findsOneWidget);

    // The subtitle Text is wrapped in a Padding with top: 2
    final paddingWithSubtitle = tester.widget<Padding>(find.widgetWithText(Padding, 'Upstairs'));
    expect(paddingWithSubtitle.padding is EdgeInsets, true);
    final e = paddingWithSubtitle.padding as EdgeInsets;
    expect(e.top, 2.0);
  });

  testWidgets('empty subtitle string is not rendered', (tester) async {
    await tester.pumpWidget(_wrap(const EntityDescription(title: 'Kitchen', subtitle: '')));
    expect(find.text('Kitchen'), findsOneWidget);
    // No subtitle rendered when empty
    expect(find.text(''), findsNothing);
  });

  testWidgets('renders badges in a Wrap with spacing and top padding of 8', (tester) async {
    final badge1 = const Chip(label: Text('12 items'));
    final badge2 = const Chip(label: Text('fragile'));

    await tester.pumpWidget(_wrap(EntityDescription(title: 'Garage', badges: [badge1, badge2])));

    // Badges present
    expect(find.byType(Chip), findsNWidgets(2));

    // Wrap container exists with expected spacing
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.spacing, 6);
    expect(wrap.runSpacing, -8);

    // The Wrap is wrapped in a Padding with top: 8
    final paddingWithWrap = tester.widget<Padding>(
      find.ancestor(of: find.byType(Wrap), matching: find.byType(Padding)),
    );
    expect((paddingWithWrap.padding as EdgeInsets).top, 8.0);
  });
}
