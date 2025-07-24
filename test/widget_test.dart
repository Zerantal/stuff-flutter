// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:stuff/main.dart';
import 'package:stuff/locations_page.dart';
import 'package:stuff/models/location_model.dart';
import 'package:stuff/rooms_page.dart';
import 'package:stuff/services/data_service_interface.dart';
import 'package:provider/provider.dart';

// --- Mocking Setup ---
// Mock DatabaseService
@GenerateNiceMocks([MockSpec<IDataService>()])
import 'widget_test.mocks.dart';

// Mock PathProvider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.'; // Use a temporary directory for tests
  }
}

// Example logger usage within a test or your app code
final _logger = Logger('TestLogger');

void main() {
  // Use a late final for the mock because it's set up in setUpAll
  late MockIDataService mockDataService;
  // StreamController for live updates in tests for watchAllLocations
  late StreamController<List<Location>> locationsStreamController;

  setUpAll(() async {
    // Configure logger for tests
    Logger.root.level = Level.ALL; // Capture all log levels
    Logger.root.onRecord.listen((record) {
      // Customize the output format if needed

      print(
        '[${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}',
      );
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('StackTrace: ${record.stackTrace}');
      }
    });

    // --- Crucial for Hive in tests (if any part of your test still indirectly uses it) ---
    // Although we mock IDataService, if any widget indirectly initializes Hive or
    // if Hive.initFlutter is still called by some code path that isn't fully mocked out,
    // this setup is a good safety measure.
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  testWidgets('My widget test with logging', (WidgetTester tester) async {
    _logger.shout('This is a SHOUT message!');
    _logger.severe('This is a SEVERE message');
    _logger.warning('This is a WARNING message');
    _logger.info('This is an INFO message');
    _logger.config('This is a CONFIG message');
    _logger.fine('This is a FINE message');
    _logger.finer('This is a FINER message');
    _logger.finest('This is a FINEST message');

    // Your test assertions
    expect(true, isTrue);
  });

  setUp(() {
    // Create a new mock and stream controller for each test
    mockDataService = MockIDataService();
    locationsStreamController = StreamController<List<Location>>.broadcast();

    // --- Default stubbing for mockDataService ---
    // Stub init method (important!)
    when(mockDataService.init()).thenAnswer((_) async {});

    // Stub watchAllLocations to return the stream from our controller
    when(
      mockDataService.watchAllLocations(),
    ).thenAnswer((_) => locationsStreamController.stream);

    when(mockDataService.getAllLocations()).thenAnswer((_) async => []);
    locationsStreamController.add([]); // Emit initial empty list for the stream

    // Stub populateSampleData
    when(mockDataService.populateSampleData()).thenAnswer((_) async {});

    // Stub dispose method
    when(mockDataService.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    locationsStreamController.close();
  });

  // Helper function to pump widget with Provider
  Future<void> pumpMyHomePageWrapper(
    WidgetTester tester, {
    IDataService? dataService,
  }) async {
    await tester.pumpWidget(
      Provider<IDataService>.value(
        value: dataService ?? mockDataService,
        child: const MaterialApp(
          // MaterialApp is needed for navigation, themes, etc.
          home: MyHomePageWrapper(),
          // For dialogs and SnackBars from MyHomePageWrapper
          // builder: (context, child) {
          //   return Overlay(
          //     initialEntries: [OverlayEntry(builder: (context) => child!)],
          //   );
          // },
        ),
      ),
    );
  }

  testWidgets('MyApp structure and initial home widget', (
    WidgetTester tester,
  ) async {
    // For MyApp, we might not need to provide IDataService if its build method
    // doesn't directly depend on it before MyHomePageWrapper is built.
    // However, MyHomePageWrapper WILL need it.
    // The main.dart setup for MyApp now includes Provider.
    // So, to test MyApp correctly, we should simulate that setup.
    await tester.pumpWidget(
      Provider<IDataService>.value(
        value: mockDataService, // Provide the mock for MyApp's child tree
        child: const MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    final MaterialApp materialApp = tester.widget(find.byType(MaterialApp));
    expect(materialApp.title, 'Stuff');
    // Ensure that Provider is indeed part of MyApp's build if it wraps MyHomePageWrapper
    expect(materialApp.home, isA<MyHomePageWrapper>());
  });

  testWidgets(
    'MyHomePageWrapper initially shows LocationsPage and correct AppBar title',
    (WidgetTester tester) async {
      // Provide an empty list of locations initially via the stream
      when(
        mockDataService.watchAllLocations(),
      ).thenAnswer((_) => Stream.value([]));
      // And for direct getAllLocations if called
      when(mockDataService.getAllLocations()).thenAnswer((_) async => []);

      await pumpMyHomePageWrapper(tester);
      await tester
          .pumpAndSettle(); // Allow StreamBuilder to process initial stream value

      expect(find.widgetWithText(AppBar, 'Locations'), findsOneWidget);
      expect(find.byType(LocationsPage), findsOneWidget);
      expect(find.byType(RoomsPage), findsNothing);
    },
  );

  testWidgets(
    'MyHomePageWrapper navigates to RoomsPage and updates AppBar by tapping View button',
    (WidgetTester tester) async {
      // Test data
      final testLocation1 = Location(
        id: 'loc1',
        name: 'Shed',
        description: 'Garden tools',
      );
      final testLocation2 = Location(
        id: 'loc2',
        name: 'Garage',
        description: 'Car and storage',
      );
      final initialLocations = [testLocation1, testLocation2];

      // Mocking getAllLocations for the initial load
      when(
        mockDataService.getAllLocations(),
      ).thenAnswer((_) async => initialLocations);

      //  Pump MyHomePageWrapper. LocationsPage's initState will call _loadLocations,
      //    which calls mockDataService.getAllLocations().
      await pumpMyHomePageWrapper(tester);
      await tester.pumpAndSettle(); // Allow FutureBuilder to resolve and build

      // Verify LocationsPage is shown and has the expected content
      expect(find.widgetWithText(AppBar, 'Locations'), findsOneWidget);
      expect(find.byType(LocationsPage), findsOneWidget);
      expect(find.text(testLocation1.name), findsOneWidget);
      expect(find.text(testLocation2.name), findsOneWidget);
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing, // Explicitly check spinner is gone
        reason: "Spinner should be gone after initial locations are loaded",
      );

      // ... (rest of the test: tapping the button, etc.)
      final viewShedButtonFinder = find.byKey(const Key('view_location_loc1'));
      expect(viewShedButtonFinder, findsOneWidget);
      await tester.tap(viewShedButtonFinder);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, testLocation1.name), findsOneWidget);

      // When navigating back:
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);
      await tester.tap(backButtonFinder);

      // getAllLocations should be called again with the same data
      when(
        mockDataService.getAllLocations(),
      ).thenAnswer((_) async => initialLocations);

      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Locations'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('MyHomePageWrapper shows developer drawer and reset works', (
    WidgetTester tester,
  ) async {
    // Mock the behavior of populateSampleData
    when(mockDataService.populateSampleData()).thenAnswer((_) async {
      // When populateSampleData is called, simulate the data changing
      // by pushing new data to the stream.
      final sampleLocations = [
        Location(id: 'sample1', name: 'Sample Location'),
      ];
      locationsStreamController.add(sampleLocations);
      // You might also need to update what getAllLocations returns if it's used elsewhere
      // when(mockDataService.getAllLocations()).thenAnswer((_) async => sampleLocations);
    });

    await pumpMyHomePageWrapper(tester);

    // Emit the initial empty list state AFTER pumping the wrapper
    locationsStreamController.add([]);
    await tester
        .pumpAndSettle(); // UI should now show empty state, not spinner.

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: "Spinner should be gone on initial empty list",
    );
    expect(
      find.textContaining('No locations found'),
      findsOneWidget,
    ); // Or your empty state message

    // ... (rest of the test: opening drawer, tapping reset) ...
    expect(find.byIcon(Icons.menu), findsOneWidget);
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(ListTile, 'Reset DB with Sample Data'),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(ListTile, 'Reset DB with Sample Data'),
    );
    await tester.pumpAndSettle(); // Dialog appears

    expect(find.text('Confirm Reset'), findsOneWidget);
    await tester.tap(find.text('Reset All Data'));
    // After tapping "Reset All Data", populateSampleData is called,
    // which (per our mock setup) will add new data to the stream.
    await tester.pumpAndSettle(); // Allow UI to update from the new stream data

    // Verify SnackBar and data
    verify(mockDataService.populateSampleData()).called(1);
    // Snackbars can be tricky, pump a bit if needed
    // await tester.pump(const Duration(milliseconds: 100)); // For "Resetting..."
    // await tester.pumpAndSettle(); // For "Database has been reset" and list update
  });
}
