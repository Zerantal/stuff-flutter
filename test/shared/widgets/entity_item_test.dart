// test/shared/widgets/entity_item_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/entity_item.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('EntityListItem', () {
    testWidgets('renders slots and padding, expands description, no trailing when null', (
      tester,
    ) async {
      const thumbKey = Key('thumb');
      const trailingKey = Key('trail');

      await tester.pumpWidget(
        _wrap(
          const EntityListItem(
            thumbnail: SizedBox(key: thumbKey, width: 24, height: 24),
            description: Text('Description'),
            trailing: null,
          ),
        ),
      );

      expect(find.byKey(thumbKey), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.byKey(trailingKey), findsNothing);

      // Thumbnail is wrapped in a Padding with right: 12
      final thumbPadding = tester.widget<Padding>(
        find.ancestor(of: find.byKey(thumbKey), matching: find.byType(Padding)).first,
      );
      final p = thumbPadding.padding as EdgeInsets;
      expect(p.right, 12.0);

      // Description is inside an Expanded
      expect(
        find.ancestor(of: find.text('Description'), matching: find.byType(Expanded)),
        findsOneWidget,
      );
    });

    testWidgets('tapping triggers onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          EntityListItem(
            thumbnail: const SizedBox(key: Key('thumb')),
            description: const Text('Desc'),
            trailing: const Icon(Icons.more_horiz, key: Key('trail')),
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('renders trailing when provided', (tester) async {
      const trailingKey = Key('trail');
      await tester.pumpWidget(
        _wrap(
          const EntityListItem(
            thumbnail: SizedBox(),
            description: Text('Desc'),
            trailing: Icon(Icons.more_horiz, key: trailingKey),
          ),
        ),
      );
      expect(find.byKey(trailingKey), findsOneWidget);
    });
  });

  group('EntityGridItem', () {
    testWidgets('renders header SizedBox(height: 120) and expands description', (tester) async {
      const thumbKey = Key('gridThumb');

      await tester.pumpWidget(
        _wrap(
          const EntityGridItem(
            thumbnail: SizedBox(key: thumbKey, width: 10, height: 10),
            description: Text('GridDesc'),
            trailing: null,
          ),
        ),
      );

      // Thumbnail sits inside a SizedBox(height: 120)
      final sized = tester.widget<SizedBox>(
        find.ancestor(of: find.byKey(thumbKey), matching: find.byType(SizedBox)).first,
      );
      expect(sized.height, 120);

      // Description is inside an Expanded within the Row
      expect(
        find.ancestor(of: find.text('GridDesc'), matching: find.byType(Expanded)),
        findsOneWidget,
      );
    });

    testWidgets('tapping triggers onTap and trailing renders', (tester) async {
      var taps = 0;
      const trailingKey = Key('gridTrail');

      await tester.pumpWidget(
        _wrap(
          EntityGridItem(
            thumbnail: const SizedBox(),
            description: const Text('Grid'),
            trailing: const Icon(Icons.more_vert, key: trailingKey),
            onTap: () => taps++,
          ),
        ),
      );

      expect(find.byKey(trailingKey), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });
}
