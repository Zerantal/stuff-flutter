// main.dart
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stuff/services/image_data_service_interface.dart';

import 'pages/rooms_page.dart';
import 'pages/locations_page.dart';
import 'models/location_model.dart';
import 'services/impl/hive_db_data_service.dart';
import 'services/utils/sample_data_populator.dart';
import 'services/data_service_interface.dart';
import 'services/impl/geolocator_location_service.dart';
import 'services/location_service_interface.dart';
import 'services/impl/local_app_image_data_service.dart';
import 'services/impl/flutter_image_picker_service.dart';
import 'services/image_picker_service_interface.dart';
import 'services/temporary_file_service_interface.dart';
import 'services/impl/path_provider_temporary_file_service.dart';

final _mainLogger = Logger('AppInitializer');

const MethodChannel _nativeLogChannel = MethodChannel('com.example.stuff/log');

Future<void> _sendToNativeLog(LogRecord record) async {
  if (!kDebugMode && record.level < Level.SEVERE) {
    // In release mode, only send SEVERE logs and above to native, unless configured otherwise
    return;
  }
  try {
    await _nativeLogChannel.invokeMethod('log', {
      'tag': record.loggerName,
      'message': '${record.level.name}: ${record.message}',
      'error': record.error?.toString(),
      'stackTrace': record.stackTrace?.toString(),
    });
  } catch (e) {
    // Fallback if platform channel fails
    final fallbackMessage =
        '[NATIVE LOG FAIL] ${record.level.name}: ${record.loggerName}: ${record.message} (Error: $e)';
    if (Logger.root.level != Level.OFF) {
      // Check if logging has been configured at all
      _mainLogger.warning(fallbackMessage, record.error, record.stackTrace);
    } else {
      debugPrint(fallbackMessage);
      if (record.error != null) debugPrint('  Error: ${record.error}');
      if (record.stackTrace != null) {
        debugPrint('  StackTrace: ${record.stackTrace}');
      }
    }
  }
}

// --- Initialization Helper Functions ---
Future<void> _configureLogging() async {
  Logger.root.level = Level.ALL; // Capture all logs

  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      final message =
          '${record.level.name}: ${record.time.toIso8601String()}: ${record.loggerName}: ${record.message}';
      debugPrint(message);
      if (record.error != null) {
        debugPrint('  ERROR: ${record.error}');
        if (record.stackTrace != null) {
          debugPrint('  STACKTRACE: ${record.stackTrace}');
        }
      } else if (record.stackTrace != null) {
        debugPrint('  STACKTRACE: ${record.stackTrace}');
      }

      if (record.level >= Level.SEVERE) {
        // Send severe errors to native even in debug
        _sendToNativeLog(record);
      }
    } else {
      // In release mode, only rely on _sendToNativeLog
      _sendToNativeLog(record);
    }

    if (!kDebugMode && record.level >= Level.SEVERE) {
      // TODO: Implement crash reporting (e.g., Sentry, Firebase Crashlytics)
    }
  });
}

Future<void> _initializeHive() async {
  _mainLogger.info("Initializing Hive...");
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    if (!Hive.isAdapterRegistered(LocationAdapter().typeId)) {
      Hive.registerAdapter(LocationAdapter());
    }
    _mainLogger.info("Hive initialized successfully.");
  } catch (e, s) {
    _mainLogger.severe("Error initializing Hive", e, s);
    rethrow; // Re-throw to be caught by runZonedGuarded or main's try-catch
  }
}

Future<IDataService> _initializeDataService() async {
  _mainLogger.info("Initializing DataService...");
  final IDataService dataService =
      HiveDbDataService(); // Or your chosen implementation
  try {
    await dataService.init();
    _mainLogger.info("DataService initialized successfully.");
    return dataService;
  } catch (e, s) {
    _mainLogger.severe("Error initializing DataService", e, s);
    rethrow;
  }
}

Future<IImageDataService?> _createLocalAppImageDataService() async {
  _mainLogger.info("Creating LocalAppImageDataService...");
  try {
    final service = await LocalAppImageDataService.create();
    _mainLogger.info("LocalAppImageDataService created successfully.");
    return service;
  } catch (e, s) {
    _mainLogger.severe('Failed to create LocalAppImageDataService', e, s);
    // Depending on how critical this is, you might rethrow or return null
    return null; // Or rethrow if it's a critical failure for app start
  }
}

// --- Main Application Entry Point --- This is where the magic happens!

Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await _configureLogging();
      _mainLogger.info(
        "AppInitializer: Flutter bindings ensured. Configuring logging...",
      );
      _mainLogger.info("Application starting...");

      // 3. Initialize Core Services
      IDataService dataService;
      try {
        await _initializeHive();
        dataService = await _initializeDataService();
      } catch (error, stackTrace) {
        _mainLogger.shout(
          'CRITICAL_ERROR_UNCAUGHT_BY_RUNZONEDGUARDED: $error',
          error,
          stackTrace,
        );
        return;
      }

      _mainLogger.info(
        "Core services initialized. Setting up providers and running app.",
      );

      // 4. Run the App with Providers
      runApp(
        MultiProvider(
          providers: [
            Provider<IDataService>.value(value: dataService),
            FutureProvider<IImageDataService?>(
              create: (_) => _createLocalAppImageDataService(),
              initialData: null,
              catchError: (context, error) {
                _mainLogger.severe(
                  'Error in FutureProvider for IImageDataService',
                  error,
                  (error is Error ? error.stackTrace : null),
                );
                return null;
              },
            ),
            // Other synchronous services can be directly provided
            Provider<ILocationService>(
              create: (_) => GeolocatorLocationService(),
            ),
            Provider<IImagePickerService>(
              create: (_) => FlutterImagePickerService(),
            ),
            Provider<ITemporaryFileService>(
              create: (_) => PathProviderTemporaryFileService(),
            ),
          ],
          child: const MyApp(),
        ),
      );
      _mainLogger.info(
        "runApp() called. Flutter application UI should now take over.",
      );
    },
    (error, stackTrace) {
      // This handler catches:
      // 1. Synchronous errors during the initial `runZonedGuarded` callback.
      // 2. Asynchronous errors that weren't caught by `await` and propagated up.
      // At this point, logging should be configured.
      _mainLogger.shout(
        'CRITICAL_ERROR_UNCAUGHT_BY_RUNZONEDGUARDED: $error',
        error,
        stackTrace,
      );
      // TODO: Consider reporting this to a crash service as well.
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stuff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyHomePageWrapper(),
    );
  }
}

enum ActiveView { locations, rooms }

class MyHomePageWrapper extends StatefulWidget {
  const MyHomePageWrapper({super.key});

  @override
  State<MyHomePageWrapper> createState() => _MyHomePageWrapperState();
}

class _MyHomePageWrapperState extends State<MyHomePageWrapper> {
  String _appBarTitle = 'Locations'; // Default title
  ActiveView _currentView = ActiveView.locations;

  // Parameters for RoomsPage if _currentView is rooms
  String? _selectedLocationId;
  String? _selectedLocationName;

  Future<void> _resetDatabaseWithSampleData() async {
    final dataService = Provider.of<IDataService>(context, listen: false);
    final imageDataService = Provider.of<IImageDataService?>(
      context,
      listen: false,
    );

    if (imageDataService == null) {
      // Handle the case where image service isn't ready.
      // This might be rare if it's a FutureProvider that has resolved,
      // but good to be defensive.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image service not available. Please try again.'),
          ),
        );
      }
      _mainLogger.warning(
        "Attempted to reset DB, but IImageDataService is null.",
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
            'Are you sure you want to reset ALL inventory data to the sample set? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Reset All Data'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database... Please wait.')),
      );

      // Use the SampleDataPopulator
      final populator = SampleDataPopulator(
        dataService: dataService,
        imageDataService: imageDataService, // Pass the potentially null service
      );

      try {
        await populator.populate(); // This now handles clearing and populating
        _mainLogger.info(
          "Sample data population successful via SampleDataPopulator.",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database has been reset with sample data.'),
            ),
          );
          // Refresh UI - consider a more robust way than just setState
          setState(() {});
        }
      } catch (e, s) {
        _mainLogger.severe("Error during sample data population: $e", e, s);
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting database: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  // Callback to update the AppBar title from child pages
  void _updateAppBarTitle(String newTitle) {
    if (mounted) {
      setState(() {
        _appBarTitle = newTitle;
      });
    }
  }

  // Method to navigate to the Rooms view
  void _navigateToRooms(Location location) {
    setState(() {
      _currentView = ActiveView.rooms;
      _selectedLocationId = location.id;
      _selectedLocationName = location.name;
    });
  }

  // Method to go back to Locations view from Rooms view
  void _navigateBackToLocations() {
    setState(() {
      _currentView = ActiveView.locations;
      _selectedLocationId = null;
      _selectedLocationName = null;
      _appBarTitle = 'Locations'; // Reset title
    });
  }

  Widget _buildBody() {
    switch (_currentView) {
      case ActiveView.locations:
        return LocationsPage(
          onViewLocationContents: _navigateToRooms,
          // If LocationsPage ever needs to dynamically set the title (e.g. "Locations (3)")
          // you could pass it like this:
          // updateAppBarTitle: _updateAppBarTitle,
        );
      case ActiveView.rooms:
        if (_selectedLocationId != null && _selectedLocationName != null) {
          return RoomsPage(
            locationId: _selectedLocationId!,
            locationName: _selectedLocationName!,
            updateAppBarTitle: _updateAppBarTitle,
          );
        }
        // Fallback or error state if parameters are missing
        // This should ideally not be reached if navigation is managed correctly
        return const Center(
          child: Text('Error: Location data missing for rooms view.'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBackToLocations = _currentView == ActiveView.rooms;

    return Scaffold(
      appBar: AppBar(
        // This is the MAIN AppBar
        title: Text(_appBarTitle),
        leading: canGoBackToLocations
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBackToLocations,
                tooltip: 'Back to Locations',
              )
            : (kDebugMode // Only show drawer button if not showing back button AND in debug mode
                  ? Builder(
                      // Use Builder to get context for Scaffold.of
                      builder: (BuildContext appBarContext) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Developer Options',
                          onPressed: () {
                            // Use appBarContext which is under the Scaffold
                            Scaffold.of(appBarContext).openDrawer();
                          },
                        );
                      },
                    )
                  : null),
      ),
      drawer: kDebugMode
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.teal),
                    child: Text(
                      'Developer Options',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dataset_outlined),
                    title: const Text('Reset DB with Sample Data'),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer first
                      await _resetDatabaseWithSampleData(); // Call the stateful method
                    },
                  ),
                  // Add other developer options here
                ],
              ),
            )
          : null,
      body: _buildBody(),
    );
  }
}
