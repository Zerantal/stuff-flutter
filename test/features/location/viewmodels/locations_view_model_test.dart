// test/features/location/viewmodels/locations_view_model_test.dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/location/viewmodels/locations_view_model.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/domain/models/room_model.dart';

import '../../../utils/mocks.dart';
import '../../../utils/dummies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockIDataService data;
  late MockIImageDataService images;
  late StreamController<List<Location>> locStream;

  setUp(() {
    data = MockIDataService();
    images = MockIImageDataService();
    locStream = StreamController<List<Location>>.broadcast();

    // The VM listens to this stream to produce LocationListItems.
    when(data.getLocationsStream()).thenAnswer((_) => locStream.stream);

    registerCommonDummies();
  });

  tearDown(() async {
    await locStream.close();
  });

  group('LocationsViewModel', () {
    test('maps getLocationsStream to List<LocationListItem>', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      final l1 = Location(id: 'L1', name: 'Home', imageGuids: ['a', 'b']);
      final l2 = Location(id: 'L2', name: 'Office', imageGuids: []);

      final firstItems = vm.locations.first;

      // Emit AFTER constructing the VM so the subscription exists
      locStream.add([l1, l2]);

      final items = await firstItems;
      expect(items.length, 2);
      expect(items[0].location, l1);
      expect(items[1].location, l2);
    });

    test('deleteLocationById: deletes location and deletes all related images', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      final loc = Location(id: 'L1', name: 'Home', imageGuids: const ['imgA', 'imgB']);

      final room1 = Room(id: 'R1', locationId: 'L1', name: 'Study', imageGuids: const ['r1A']);
      final room2 = Room(
        id: 'R2',
        locationId: 'L1',
        name: 'Office',
        imageGuids: const ['r2A', 'r2B'],
      );

      when(data.getLocationById('L1')).thenAnswer((_) async => loc);
      when(data.getRoomsForLocation('L1')).thenAnswer((_) async => [room1, room2]);
      when(data.deleteLocation('L1')).thenAnswer((_) async {});

      await vm.deleteLocationById('L1');

      verify(data.getLocationById('L1')).called(1);
      verify(data.getRoomsForLocation('L1')).called(1);
      verify(data.deleteLocation('L1')).called(1);

      // Verify the extension ultimately called deleteImage for every guid.
      final v = verify(images.deleteImage(captureAny));
      v.called(5); // imgA, imgB, r1A, r2A, r2B
      final capturedGuids = v.captured.cast<String>().toSet();
      expect(capturedGuids, {'imgA', 'imgB', 'r1A', 'r2A', 'r2B'});
    });

    test('deleteLocationById: returns early if location not found', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      when(data.getLocationById('missing')).thenAnswer((_) async => null);

      await vm.deleteLocationById('missing');

      verify(data.getLocationById('missing')).called(1);
      verifyNever(data.getRoomsForLocation(any));
      verifyNever(data.deleteLocation(any));
      verifyNever(images.deleteImage(any));
    });

    test('deleteLocationById: rethrow unhandled errors and doesn’t delete images', () async {
      final vm = LocationsViewModel(dataService: data, imageDataService: images);

      final loc = Location(id: 'L1', name: 'Home', imageGuids: const []);
      when(data.getLocationById('L1')).thenAnswer((_) async => loc);
      when(data.getRoomsForLocation('L1')).thenThrow(Exception('boom'));

      // Should throw
      // await expectLater(vm.deleteLocationById('L1'), throwsA(isA<Exception>().having((e) => e., description, matcher))); ;
      await expectLater(
        vm.deleteLocationById('L1'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'toString', 'Exception: boom')),
      );

      verify(data.getLocationById('L1')).called(1);
      verify(data.getRoomsForLocation('L1')).called(1);
      verifyNever(images.deleteImage(any));
    });
  });
}
