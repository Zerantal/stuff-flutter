// test/features/location/pages/locations_view_mockito_test.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:stuff/features/location/pages/locations_page.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/shared/widgets/empty_list_state.dart';
import 'package:stuff/shared/widgets/entity_item.dart';

import '../../../utils/test_logger_manager.dart';
import '../../../utils/test_router.dart';
import '../../../utils/ui_runner_helper.dart';
import '../../../utils/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<List<Location>> controller;
  late TestLoggerManager logs;

  setUp(() {
    controller = StreamController<List<Location>>.broadcast();
    logs = TestLoggerManager();
    logs.startCapture();
  });

  tearDown(() async {
    await controller.close();
    logs.stopCapture();
  });

  Future<ProvidedMockServices> pump(
    WidgetTester tester, {
    Size size = const Size(600, 800),
    List<NavigatorObserver> observers = const <NavigatorObserver>[],
  }) async {
    return pumpPageWithServices(
      tester,
      pageWidget: const LocationsPage(),
      mediaQueryData: MediaQueryData(size: size),
      navigatorObservers: observers,
      onMocksReady: (m) {
        when(m.dataService.getLocationsStream()).thenAnswer((_) => controller.stream);
      },
    );
  }

  group('LocationsView + Mockito', () {
    testWidgets('loading → empty state', (tester) async {
      await pump(tester);
      await tester.pump(); // initial frame: skeleton list
      expect(find.byType(ListView), findsOneWidget);

      // empty
      controller.add(const <Location>[]);
      await tester.pumpAndSettle();
      expect(find.textContaining('No locations found'), findsOneWidget);
    });

    testWidgets('list vs grid based on width', (tester) async {
      // Narrow list
      await pump(tester, size: const Size(600, 800));
      controller.add([
        Location(id: 'L1', name: 'Home', imageGuids: const []),
        Location(id: 'L2', name: 'Office', imageGuids: const []),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.byType(EntityListItem), findsNWidgets(2));
      expect(find.byType(EntityGridItem), findsNothing);

      // Wide grid
      await pump(tester, size: const Size(1000, 800));
      controller.add([
        Location(id: 'L1', name: 'Home', imageGuids: const []),
        Location(id: 'L2', name: 'Office', imageGuids: const []),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.byType(EntityListItem), findsNothing);
      expect(find.byType(EntityGridItem), findsNWidgets(2));
    });

    testWidgets('FAB switches extended by width', (tester) async {
      controller.add(const <Location>[]);

      // Narrow → regular FAB
      await pump(tester, size: const Size(600, 800));
      await tester.pumpAndSettle();
      final narrowFab = tester.widget<FloatingActionButton>(
        find.byKey(const ValueKey('add_location_fab')),
      );
      expect(narrowFab.isExtended, isFalse);

      // Wide → extended FAB
      await pump(tester, size: const Size(900, 800));
      await tester.pumpAndSettle();
      final wideFab = tester.widget<FloatingActionButton>(
        find.byKey(const ValueKey('add_location_fab')),
      );
      expect(wideFab.isExtended, isTrue);
    });

    testWidgets('delete flow - confirm deletion and success snackbar', (tester) async {
      final mocks = await pump(tester);
      final loc = Location(name: 'Office', id: 'abc');
      controller.add([loc]);

      await tester.pumpAndSettle();

      expect(find.byType(EmptyListState), findsNothing);
      expect(find.byType(EntityListItem), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('context_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // setup some mocks on data service so that VM deletes to completion
      when(mocks.dataService.getLocationById('abc')).thenAnswer((_) => Future.value(loc));

      // Confirm dialog
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      verify(mocks.dataService.deleteLocation('abc')).called(1);
      expect(find.text('Location deleted'), findsOneWidget);
    });

    testWidgets('delete flow - error shows error snackbar', (tester) async {
      final loc = Location(name: 'Garage', id: 'id-1');
      final mocks = await pump(tester);
      when(mocks.dataService.getLocationById('id-1')).thenAnswer((_) => Future.value(loc));
      when(mocks.dataService.deleteLocation('id-1')).thenThrow(Exception('boom'));

      controller.add([loc]);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('context_action_menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_btn')));
      await tester.pumpAndSettle();
      final confirmBtnFinder = find.byKey(const ValueKey('conf_dialog_confirm_btn'));
      await tester.tap(confirmBtnFinder); // confirm
      await tester.pumpAndSettle();

      verify(mocks.dataService.deleteLocation('id-1')).called(1);
      expect(find.text('Delete failed'), findsOneWidget);
    });

    group('NavigatorObserver assertions (AppRoutes pushes)', () {
      testWidgets('FAB pushes add location route', (tester) async {
        final observer = MockNavigatorObserver();
        final router = makeTestRouter(home: const LocationsPage(), observers: [observer]);

        await pumpPageWithServices(
          tester,
          pageWidget: const LocationsPage(),
          navigatorObservers: [observer],
          router: router,
          onMocksReady: (m) {
            when(m.dataService.getLocationsStream()).thenAnswer((_) => controller.stream);
          },
        );

        controller.add(const <Location>[]);
        await tester.pumpAndSettle();

        reset(observer);
        await tester.tap(find.byKey(const ValueKey('add_location_fab')));
        await tester.pumpAndSettle();

        verify(observer.didPush(any, any)).called(1);

        expect(find.byKey(const ValueKey('route_locationsAdd')), findsOneWidget);
      });

      testWidgets('tapping a card pushes rooms route', (tester) async {
        final loc = Location(name: 'Home', id: 'L1');
        final observer = MockNavigatorObserver();
        final router = makeTestRouter(home: const LocationsPage(), observers: [observer]);

        await pumpPageWithServices(
          tester,
          pageWidget: const LocationsPage(),
          navigatorObservers: [observer],
          router: router,
          onMocksReady: (m) {
            when(m.dataService.getLocationsStream()).thenAnswer((_) => controller.stream);
          },
        );

        await tester.pumpAndSettle();
        controller.add([loc]);

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
        final router = makeTestRouter(home: const LocationsPage(), observers: [observer]);

        await pumpPageWithServices(
          tester,
          pageWidget: const LocationsPage(),
          navigatorObservers: [observer],
          router: router,
          onMocksReady: (m) {
            when(m.dataService.getLocationsStream()).thenAnswer((_) => controller.stream);
          },
        );

        controller.add([loc]);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('context_action_menu')));
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
