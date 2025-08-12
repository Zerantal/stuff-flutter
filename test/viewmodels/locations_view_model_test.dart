// test/viewmodels/locations_view_model_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:stuff/viewmodels/locations_view_model.dart';
import 'package:stuff/services/data_service_interface.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/models/location_model.dart';

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
  });

  tearDown(() async {
    await ctrl.close();
  });

  group('LocationsViewModel', () {
    test('refresh() asks data service to reload', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      await vm.refresh();
      verify(() => data.getAllLocations()).called(1);
    });

    test('emits items with null image when no guid', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      // Collect the first emission
      final itemsFuture = vm.locations?.first;

      // Build a Location with no images. Adjust constructor to your model.
      final loc = Location(
        id: 'L0',
        name: 'No Image',
        description: null,
        address: null,
        images: const [],
      );

      ctrl.add([loc]);
      final items = await itemsFuture;

      expect(items, hasLength(1));
      expect(items?.single.location.id, 'L0');
      expect(items?.single.image, isNull);
      verifyNever(() => images.getImage(any(), verifyExists: any(named: 'verifyExists')));
    });

    test('emits items with ImageRef from first guid (no existence check)', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      when(
        () => images.getImage('g1', verifyExists: any(named: 'verifyExists')),
      ).thenAnswer((_) async => const ImageRef.file('/tmp/a.jpg'));

      final loc = Location(
        id: 'L1',
        name: 'Has Image',
        description: null,
        address: null,
        images: const ['g1', 'g2'],
      );

      final itemsFuture = vm.locations?.first;
      ctrl.add([loc]);

      final items = await itemsFuture;
      expect(items, hasLength(1));
      expect(items?.first.location.id, 'L1');
      expect(items?.first.image, isA<FileImageRef>());
      // verify we did NOT request existence check (should be false)
      verify(() => images.getImage('g1', verifyExists: false)).called(1);
    });

    test('image service throwing => item.image is null', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      when(
        () => images.getImage('bad', verifyExists: any(named: 'verifyExists')),
      ).thenThrow(StateError('boom'));

      final loc = Location(
        id: 'L2',
        name: 'Bad Image',
        description: null,
        address: null,
        images: const ['bad'],
      );

      final itemsFuture = vm.locations?.first;
      ctrl.add([loc]);
      final items = await itemsFuture;

      expect(items?.single.image, isNull);
    });
  });
}
