// test/features/location/pages/edit_location_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/location/pages/edit_location_page.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/features/location/viewmodels/edit_location_view_model.dart';

import '../../../utils/mocks.dart';
import '../../../utils/dummies.dart';
import '../../../utils/ui_runner_helper.dart';

void main() {
  setUp(() {
    registerCommonDummies();
  });

  group('EditLocationPage', () {
    testWidgets('ADD mode: renders form and image manager once temp session is ready', (
      tester,
    ) async {
      await pumpWithNotifierVm(
        tester,
        home: const EditLocationPage(),
        vmFactory: (m) => EditLocationViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          locationService: m.locationService,
          tempFileService: m.temporaryFileService,
        ),
        afterInit: (vm, m) async {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          await vm.initForNew();
        },
      );

      await tester.pumpAndSettle();

      // Title should indicate add mode
      expect(find.text('Add Location'), findsOneWidget);

      // Form fields present
      expect(find.byKey(const Key('loc_name')), findsOneWidget);
      expect(find.byKey(const Key('loc_desc')), findsOneWidget);
      expect(find.byKey(const Key('loc_address')), findsOneWidget);

      // GPS button present (don’t assert behavior here)
      expect(find.byKey(const Key('use_current_location_btn')), findsOneWidget);

      // Image manager appears once the temp session is available
      expect(find.byKey(const Key('image_manager')), findsOneWidget);
    });

    testWidgets('EDIT mode: pre-populates fields from dataService.getLocationById', (tester) async {
      const locId = 'L1';
      final location = Location(
        id: locId,
        name: 'Office',
        address: '123 Main St',
        description: 'My office location',
        imageGuids: const <String>[],
      );

      await pumpWithNotifierVm(
        tester,
        home: const EditLocationPage(),
        vmFactory: (m) => EditLocationViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          tempFileService: m.temporaryFileService,
          locationService: m.locationService,
        ),
        afterInit: (vm, m) async {
          when(m.dataService.getLocationById('L1')).thenAnswer((_) async => location);
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          await vm.initForEdit('L1');
        },
      );

      await tester.pumpAndSettle();

      // Title should indicate edit mode
      expect(find.text('Edit Location'), findsOneWidget);

      // Assert form fields are pre-populated
      final nameField = tester.widget<TextFormField>(find.byKey(const Key('loc_name')));
      final descField = tester.widget<TextFormField>(find.byKey(const Key('loc_desc')));
      final addrField = tester.widget<TextFormField>(find.byKey(const Key('loc_address')));

      expect(nameField.controller?.text, equals('Office'));
      expect(descField.controller?.text, equals('My office location'));
      expect(addrField.controller?.text, equals('123 Main St'));

      // Image manager present in edit mode as well (session started)
      expect(find.byKey(const Key('image_manager')), findsOneWidget);

      // Sanity: GPS button still present
      expect(find.byKey(const Key('use_current_location_btn')), findsOneWidget);
    });

    testWidgets('Use GPS failure shows SnackBar', (tester) async {
      await pumpWithNotifierVm(
        tester,
        home: const EditLocationPage(),
        vmFactory: (m) => EditLocationViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          tempFileService: m.temporaryFileService,
          locationService: m.locationService,
        ),
        afterInit: (vm, m) async {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());

          // Cause VM.getCurrentAddress() to return false internally
          // by making the location service return null.
          when(m.locationService.getCurrentAddress()).thenAnswer((_) async => null);
          await vm.initForNew();
        },
      );

      await tester.pumpAndSettle();

      // Tap the GPS button
      final gpsBtn = find.byKey(const Key('use_current_location_btn'));
      expect(gpsBtn, findsOneWidget);

      await tester.tap(gpsBtn);
      await tester.pumpAndSettle();

      // SnackBar should appear
      expect(find.text('Unable to get current location'), findsOneWidget);
    });

    testWidgets('Save with empty name shows validation error', (tester) async {
      await pumpWithNotifierVm(
        tester,
        home: const EditLocationPage(),
        vmFactory: (m) => EditLocationViewModel(
          dataService: m.dataService,
          imageDataService: m.imageDataService,
          tempFileService: m.temporaryFileService,
          locationService: m.locationService,
        ),
        afterInit: (vm, m) async {
          when(
            m.temporaryFileService.startSession(label: anyNamed('label')),
          ).thenAnswer((_) async => MockTempSession());
          await vm.initForNew();
        },
      );

      await tester.pumpAndSettle();

      // Ensure the name field starts empty (default)
      final nameFieldFinder = find.byKey(const Key('loc_name'));
      expect(nameFieldFinder, findsOneWidget);
      final nameField = tester.widget<TextFormField>(nameFieldFinder);
      expect(nameField.controller?.text ?? '', isEmpty);

      // Tap Save FAB
      final saveFab = find.byKey(const Key('save_entity_fab'));
      expect(saveFab, findsOneWidget);

      await tester.tap(saveFab);
      await tester.pumpAndSettle();

      // Validation error should be visible
      expect(find.text('Name is required'), findsOneWidget);

      // Clear the error by entering a valid name and saving again
      await tester.enterText(nameFieldFinder, 'My Location');
      await tester.pump(); // let form rebuild
      await tester.tap(saveFab);
      await tester.pumpAndSettle();

      // Error should be gone now
      expect(find.text('Name is required'), findsNothing);
    });
  });
}
