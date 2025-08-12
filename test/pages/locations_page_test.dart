// test/pages/locations_page_test.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:stuff/features/location/pages/locations_page.dart';
import 'package:stuff/services/contracts/data_service_interface.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/image/image_ref.dart';

class MockDataService extends Mock implements IDataService {}

class MockImageDataService extends Mock implements IImageDataService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataService data;
  late MockImageDataService images;
  late StreamController<List<Location>> ctrl;

  setUp(() {
    data = MockDataService();
    images = MockImageDataService();
    ctrl = StreamController<List<Location>>.broadcast();

    when(() => data.getLocationsStream()).thenAnswer((_) => ctrl.stream);
    when(() => data.getAllLocations()).thenAnswer((_) async {
      return <Location>[];
    });
    // Default image ref (if needed)
    when(
      () => images.getImage(any(), verifyExists: any(named: 'verifyExists')),
    ).thenAnswer((_) async => const ImageRef.file('/tmp/f.jpg'));
  });

  tearDown(() async {
    await ctrl.close();
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        Provider<IDataService>.value(value: data),
        Provider<IImageDataService>.value(value: images),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('shows empty state when no locations', (tester) async {
    await tester.pumpWidget(wrap(const LocationsPage()));
    // Emit empty list
    ctrl.add(const <Location>[]);
    await tester.pumpAndSettle();

    expect(find.textContaining('No locations found'), findsOneWidget);
    expect(find.text('Add First Location'), findsOneWidget);
  });

  testWidgets('renders a card per location item', (tester) async {
    await tester.pumpWidget(wrap(const LocationsPage()));

    final l1 = Location(
      id: 'A',
      name: 'Alpha',
      description: 'desc',
      address: 'addr',
      images: const ['g1'],
    );
    final l2 = Location(id: 'B', name: 'Beta', description: null, address: null, images: const []);

    ctrl.add(<Location>[l1, l2]);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('location_card_A')), findsOneWidget);
    expect(find.byKey(const Key('location_card_B')), findsOneWidget);

    // Thumbnail should exist for each card (placeholder or real)
    expect(find.byKey(const Key('location_thumb_A')), findsOneWidget);
    expect(find.byKey(const Key('location_thumb_B')), findsOneWidget);
  });
}
