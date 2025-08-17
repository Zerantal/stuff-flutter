// test/features/location/pages/locations_view_mockito_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/location/pages/locations_page.dart' show LocationsView;
import 'package:stuff/features/location/viewmodels/locations_view_model.dart';
import 'package:stuff/features/location/widgets/location_card.dart';
import 'package:stuff/features/location/widgets/grid_location_card.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/image/image_ref.dart';

import '../../../utils/test_logger_manager.dart';
import '../../../utils/test_router.dart';
import '../../../utils/ui_runner_helper.dart'; // pumpPageWithProviders
import 'locations_page_integration_test.mocks.dart';

@GenerateMocks([LocationsViewModel])
@GenerateNiceMocks([MockSpec<NavigatorObserver>()])
// class MockLocationsViewModel extends Mock implements LocationsViewModel {}
// class MockNavigatorObserver extends Mock implements NavigatorObserver {}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocationsViewModel vm;
  late StreamController<List<LocationListItem>> controller;
  TestLoggerManager logManager = TestLoggerManager();

  setUp(() {
    vm = MockLocationsViewModel();
    controller = StreamController<List<LocationListItem>>.broadcast();
    logManager.startCapture();
    when(vm.locations).thenAnswer((_) => controller.stream);
    when(vm.refresh()).thenAnswer((_) async {});
    when(vm.deleteLocationById(any)).thenAnswer((_) => Future<void>.value());
  });

  tearDown(() async {
    await controller.close();
    logManager.stopCapture();
  });

  group('LocationsView + Mockito', () {
    testWidgets('loading → empty state', (tester) async {
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );
      await tester.pumpAndSettle();

      // waiting -> skeleton ListView
      expect(find.byType(ListView), findsOneWidget);

      // empty
      controller.add(const <LocationListItem>[]);
      await tester.pumpAndSettle();
      expect(find.textContaining('No locations found'), findsOneWidget);
    });

    testWidgets('list vs grid based on width', (tester) async {
      final items = <LocationListItem>[
        LocationListItem(
          location: Location(name: 'Kitchen', id: 'K'),
          images: const <ImageRef>[],
        ),
        LocationListItem(
          location: Location(name: 'Lounge', id: 'L'),
          images: const <ImageRef>[],
        ),
      ];

      // Narrow → list
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );
      controller.add(items);
      await tester.pumpAndSettle();
      expect(find.byType(LocationCard), findsNWidgets(2));
      expect(find.byType(GridLocationCard), findsNothing);

      // Wide → grid
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(1000, 800)),
      );
      controller.add(items);
      await tester.pumpAndSettle();
      expect(find.byType(GridLocationCard), findsNWidgets(2));
      expect(find.byType(LocationCard), findsNothing);
    });

    testWidgets('FAB switches extended by width', (tester) async {
      controller.add(const <LocationListItem>[]);

      // Narrow → regular FAB
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );
      await tester.pumpAndSettle();
      final narrowFab = tester.widget<FloatingActionButton>(
        find.byKey(const ValueKey('add_location_fab')),
      );
      expect(narrowFab.isExtended, isFalse);

      // Wide → extended FAB
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(900, 800)),
      );
      await tester.pumpAndSettle();
      final wideFab = tester.widget<FloatingActionButton>(
        find.byKey(const ValueKey('add_location_fab')),
      );
      expect(wideFab.isExtended, isTrue);
    });

    testWidgets('pull-to-refresh calls vm.refresh', (tester) async {
      controller.add(const <LocationListItem>[]);

      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );
      await tester.pumpAndSettle();

      final riFinder = find.byKey(const Key('locations_refresh_indicator'));
      expect(riFinder, findsOneWidget);

      // ignore: invalid_use_of_protected_member
      final state = tester.state<RefreshIndicatorState>(riFinder);
      state.show();
      await tester.pumpAndSettle();

      verify(vm.refresh()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('delete flow - confirm deletion and success snackbar', (tester) async {
      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );

      final loc = Location(name: 'Office', id: 'abc');
      controller.add([LocationListItem(location: loc, images: const <ImageRef>[])]);
      await tester.pumpAndSettle();

      expect(find.textContaining('No locations found'), findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byKey(const ValueKey('location_card_abc')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('location_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(vm.deleteLocationById('abc')).called(1);
      expect(find.text('Location deleted'), findsOneWidget);
    });

    testWidgets('delete flow - error shows error snackbar', (tester) async {
      when(vm.deleteLocationById(any)).thenThrow(Exception('boom'));

      await pumpPageWithProviders<LocationsViewModel>(
        tester,
        pageWidget: const LocationsView(),
        mockViewModel: vm,
        mediaQueryData: const MediaQueryData(size: Size(600, 800)),
      );
      final loc = Location(name: 'Garage', id: 'id-1');
      controller.add([LocationListItem(location: loc, images: const <ImageRef>[])]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('location_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_btn')));
      await tester.pumpAndSettle();
      final confirmBtnFinder = find.byKey(const ValueKey('conf_dialog_confirm_btn'));
      await tester.tap(confirmBtnFinder); // confirm
      await tester.pumpAndSettle();

      verify(vm.deleteLocationById('id-1')).called(1);
      expect(find.text('Delete failed'), findsOneWidget);
    });

    group('NavigatorObserver assertions (AppRoutes pushes)', () {
      testWidgets('FAB pushes add location route', (tester) async {
        final observer = MockNavigatorObserver();
        final router = makeTestRouter(home: const LocationsView(), observers: [observer]);

        await pumpPageWithProviders<LocationsViewModel>(
          tester,
          pageWidget: const LocationsView(),
          mockViewModel: vm,
          mediaQueryData: const MediaQueryData(size: Size(900, 800)), // wide → extended FAB
          navigatorObservers: const [],
          router: router,
        );
        controller.add(const <LocationListItem>[]);
        await tester.pumpAndSettle();

        reset(observer);
        await tester.tap(find.byKey(const ValueKey('add_location_fab')));
        await tester.pumpAndSettle();

        verify(observer.didPush(any, any)).called(1);

        expect(find.byKey(const ValueKey('route_locationsAdd')), findsOneWidget);
      });

      testWidgets('tapping a card pushes rooms route', (tester) async {
        final loc = Location(name: 'Hall', id: 'L1');
        final observer = MockNavigatorObserver();
        final router = makeTestRouter(home: const LocationsView(), observers: [observer]);

        await pumpPageWithProviders<LocationsViewModel>(
          tester,
          pageWidget: const LocationsView(),
          mockViewModel: vm,
          mediaQueryData: const MediaQueryData(size: Size(600, 800)), // narrow → list
          navigatorObservers: const [],
          router: router,
        );
        await tester.pumpAndSettle();
        controller.add([LocationListItem(location: loc, images: const <ImageRef>[])]);

        reset(observer);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        verify(observer.didPush(any, any)).called(1);

        expect(find.byKey(const ValueKey('route_rooms')), findsOneWidget);
      });

      testWidgets('overflow - Edit pushes edit route', (tester) async {
        final loc = Location(name: 'Home', id: 'L2');
        final observer = MockNavigatorObserver();
        final router = makeTestRouter(home: const LocationsView(), observers: [observer]);

        await pumpPageWithProviders<LocationsViewModel>(
          tester,
          pageWidget: const LocationsView(),
          mockViewModel: vm,
          mediaQueryData: const MediaQueryData(size: Size(600, 800)),
          navigatorObservers: const [],
          router: router,
        );
        controller.add([LocationListItem(location: loc, images: const <ImageRef>[])]);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('location_action_menu')));
        await tester.pumpAndSettle();
        reset(observer);
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        verify(observer.didPush(any, any)).called(1);

        expect(find.byKey(const ValueKey('route_locationsEdit')), findsOneWidget);
      });
    });
  });
}
