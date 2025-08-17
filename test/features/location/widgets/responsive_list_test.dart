// test/features/location/widgets/responsive_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/features/location/widgets/responsive_list.dart';
import 'package:stuff/features/location/widgets/location_card.dart';
import 'package:stuff/features/location/widgets/grid_location_card.dart';
import 'package:stuff/features/location/viewmodels/locations_view_model.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/image/image_ref.dart';

Widget _wrapWithWidth(Widget child, double width) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 800)),
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(width: width, child: child),
      ),
    ),
  );
}

void main() {
  group('ResponsiveLocations', () {
    testWidgets('renders LocationCard for narrow widths (< 720)', (tester) async {
      final items = <LocationListItem>[
        LocationListItem(
          location: Location(name: 'Kitchen'),
          images: const <ImageRef>[],
        ),
        LocationListItem(
          location: Location(name: 'Lounge'),
          images: const <ImageRef>[],
        ),
      ];

      await tester.pumpWidget(
        _wrapWithWidth(
          ResponsiveLocations(items: items, onView: (_) {}, onEdit: (_) {}, onDelete: (_) {}),
          600,
        ),
      );

      expect(find.byType(LocationCard), findsNWidgets(2));
      expect(find.byType(GridLocationCard), findsNothing);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders GridLocationCard for wide widths (>= 720)', (tester) async {
      final items = <LocationListItem>[
        LocationListItem(
          location: Location(name: 'Study'),
          images: const <ImageRef>[],
        ),
        LocationListItem(
          location: Location(name: 'Office'),
          images: const <ImageRef>[],
        ),
      ];

      await tester.pumpWidget(
        _wrapWithWidth(
          ResponsiveLocations(items: items, onView: (_) {}, onEdit: (_) {}, onDelete: (_) {}),
          1000,
        ),
      );

      expect(find.byType(GridLocationCard), findsNWidgets(2));
      expect(find.byType(LocationCard), findsNothing);
      expect(find.byType(GridView), findsOneWidget);

      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2); // width 1000 -> 2 columns
    });

    testWidgets('uses 3 columns at >= 1100px', (tester) async {
      final items = <LocationListItem>[
        LocationListItem(
          location: Location(name: 'A'),
          images: const <ImageRef>[],
        ),
        LocationListItem(
          location: Location(name: 'B'),
          images: const <ImageRef>[],
        ),
        LocationListItem(
          location: Location(name: 'C'),
          images: const <ImageRef>[],
        ),
      ];

      await tester.pumpWidget(
        _wrapWithWidth(
          ResponsiveLocations(items: items, onView: (_) {}, onEdit: (_) {}, onDelete: (_) {}),
          1200,
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });

    testWidgets('tap on an item calls onView', (tester) async {
      final a = Location(name: 'Hall');
      Location? lastViewed;

      final items = <LocationListItem>[LocationListItem(location: a, images: const <ImageRef>[])];

      await tester.pumpWidget(
        _wrapWithWidth(
          ResponsiveLocations(
            items: items,
            onView: (l) => lastViewed = l,
            onEdit: (_) {},
            onDelete: (_) {},
          ),
          600,
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(identical(lastViewed, a), isTrue);
    });
  });
}
