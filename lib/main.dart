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
import 'routing/app_routes.dart';
import 'pages/locations_page.dart';
import 'pages/edit_location_page.dart';
import 'pages/containers_page.dart';
import 'pages/items_page.dart';
import 'models/location_model.dart';
import 'models/item_page_arguments.dart';
import 'models/room_data.dart';
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
import 'notifiers/app_bar_title_notifier.dart';

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
    rethrow;
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
    return null; // Handled by FutureProvider's catchError
  }
}

/// Data class to hold essential initialized services.
class EssentialServices {
  final IDataService dataService;
  // Add other synchronously initialized, essential services here if any in the future

  EssentialServices({required this.dataService});
}

/// Initializes core application services that MUST be available before the app runs.
Future<EssentialServices> _initializeAppServices() async {
  _mainLogger.info("Starting core application services initialization...");

  // 1. Configure Logging (should be done first)
  await _configureLogging();

  // 2. Initialize Hive (dependency for DataService)
  await _initializeHive();

  // 3. Initialize DataService (depends on Hive)
  final dataService = await _initializeDataService();

  _mainLogger.info("Core application services initialized successfully.");
  return EssentialServices(dataService: dataService);
}

// --- Main Application Entry Point --- This is where the magic happens!
Future<void> main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _mainLogger.info("Flutter bindings ensured.");

      EssentialServices essentialServices;
      try {
        essentialServices = await _initializeAppServices();
      } catch (error, stackTrace) {
        _mainLogger.shout(
          'CRITICAL FAILURE during core services initialization. App cannot start.',
          error,
          stackTrace,
        );
        // TODO: display error page to user:
        // i.e., runApp(ErrorDisplayApp(error))
        return;
      }

      _mainLogger.info(
        "Essential services obtained. Setting up providers and running UI.",
      );

      runApp(
        MultiProvider(
          providers: [
            Provider<IDataService>.value(value: essentialServices.dataService),
            // --- Other services that are quick to create or don't need async init ---
            Provider<ILocationService>(
              create: (_) {
                _mainLogger.info("Creating GeolocatorLocationService.");
                return GeolocatorLocationService();
              },
            ),
            Provider<IImagePickerService>(
              create: (_) {
                _mainLogger.info("Creating FlutterImagePickerService.");
                return FlutterImagePickerService();
              },
            ),
            Provider<ITemporaryFileService>(
              create: (_) {
                _mainLogger.info("Creating PathProviderTemporaryFileService.");
                return PathProviderTemporaryFileService();
              },
            ),
            // --- Asynchronously initialized services (can be loaded while showing initial UI) ---
            FutureProvider<IImageDataService?>(
              create: (_) => _createLocalAppImageDataService(),
              initialData: null,
              catchError: (context, error) {
                _mainLogger.severe(
                  'FutureProvider for IImageDataService caught an error during creation.',
                  error,
                  (error is Error ? error.stackTrace : StackTrace.current),
                );
                return null;
              },
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
        'GLOBAL_UNCAUGHT_ERROR in runZonedGuarded: $error',
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
      ),
      initialRoute: AppRoutes.locations,
      onGenerateRoute: _onGenerateRoute,
    );
  }

  // Route generator
  static Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    _mainLogger.info("Navigating to route: ${settings.name}");
    switch (settings.name) {
      case AppRoutes.locations:
        return MaterialPageRoute(
          builder: (_) => MyHomePageWrapper(
            initialPageBuilder: (context) => const LocationsPage(),
            appBarTitle: 'Locations',
            floatingActionButtonBuilder: (fabContext) {
              return FloatingActionButton(
                key: const ValueKey('add_location_fab'), // Good for testing
                onPressed: () {
                  Navigator.of(fabContext).pushNamed(AppRoutes.addLocation);
                },
                tooltip: 'Add Location',
                child: const Icon(Icons.add_location_alt_outlined),
              );
            },
          ),
        );
      case AppRoutes.addLocation:
        return MaterialPageRoute(
          builder: (_) => MyHomePageWrapper(
            // Assuming EditLocationPage uses the common scaffold
            initialPageBuilder: (context) =>
                const EditLocationPage(), // No initialLocation for new
            appBarTitle: 'Add New Location',
            showBackButton: true,
          ),
        );
      case AppRoutes.editLocation:
        if (settings.arguments is Location) {
          final location = settings.arguments as Location;
          return MaterialPageRoute(
            builder: (_) => MyHomePageWrapper(
              // Assuming EditLocationPage uses the common scaffold
              initialPageBuilder: (context) =>
                  EditLocationPage(initialLocation: location),
              appBarTitle: 'Edit ${location.name}',
              showBackButton: true,
            ),
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.editLocation}: ${settings.arguments}",
        );
        return _errorRoute("Invalid arguments for Edit Location page");
      case AppRoutes.rooms:
        if (settings.arguments is Location) {
          // Expecting a Location object
          final location = settings.arguments as Location;
          return MaterialPageRoute(
            builder: (_) => MyHomePageWrapper(
              initialPageBuilder: (context) => RoomsPage(
                location: location,
                updateAppBarTitle: // Pass the actual updateAppBarTitle function from MyHomePageWrapper's state
                (title) => Provider.of<AppBarTitleNotifier>(
                  context,
                  listen: false,
                ).setTitle(title),
              ),
              appBarTitle:
                  location.name, // Initial title, can be updated by RoomsPage
              showBackButton: true,
              // Potentially configure FAB for MyHomePageWrapper here if it's global
            ),
            settings: settings, // Pass along settings for nested navigation
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.rooms}: Expected Location, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Rooms page");

      case AppRoutes.containers:
        if (settings.arguments is RoomData) {
          final roomData = settings.arguments as RoomData;
          return MaterialPageRoute(
            builder: (_) => MyHomePageWrapper(
              // Assuming ContainersPage also uses the wrapper
              initialPageBuilder: (context) => ContainersPage(
                roomData: roomData,
                // updateAppBarTitle: (title) => Provider.of<AppBarTitleNotifier>(context, listen: false).setTitle(title), // If ContainersPage updates title
              ),
              appBarTitle:
                  'Contents of ${roomData.roomName}', // Set initial AppBar title
              showBackButton: true,
            ),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.containers}: Expected RoomData, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Containers page");

      // case AppRoutes.addRoom:
      //   if (settings.arguments is Map<String, String>) {
      //     final args = settings.arguments as Map<String, String>;
      //     final locationId = args['locationId'];
      //     final locationName = args['locationName'];
      //     if (locationId != null && locationName != null) {
      //       return MaterialPageRoute(
      //         builder: (_) => MyHomePageWrapper( // Assuming AddRoomPage also uses the wrapper
      //           initialPageBuilder: (context) => EditRoomPage( // You'll need to create AddRoomPage
      //             locationId: locationId,
      //             locationName: locationName,
      //             // updateAppBarTitle: ...
      //           ),
      //           appBarTitle: 'Add Room to $locationName',
      //           showBackButton: true,
      //         ),
      //         settings: settings,
      //       );
      //     }
      //   }
      //   _logger.severe("Incorrect arguments for ${AppRoutes.addRoom}: Expected Map with locationId & locationName, got ${settings.arguments?.runtimeType}");
      //   return _errorRoute("Invalid arguments for Add Room page");

      case AppRoutes.items:
        if (settings.arguments is ItemPageArguments) {
          final itemArgs = settings.arguments as ItemPageArguments;
          // No longer needs MyHomePageWrapper if ItemsPage has its own Scaffold
          return MaterialPageRoute(
            builder: (_) => ItemsPage(args: itemArgs),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.items}: Expected ItemPageArguments, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Items page");

      // case AppRoutes.addContainer:
      //   if (settings.arguments is Map<String, String>) {
      //     final args = settings.arguments as Map<String, String>;
      //     final roomId = args['roomId'];
      //     final roomName = args['roomName'];
      //     // ... other IDs if needed by AddContainerPage ...
      //
      //     if (roomId != null && roomName != null) {
      //       return MaterialPageRoute(
      //         // Assuming AddContainerPage has its own Scaffold or is wrapped as needed
      //         builder: (_) => AddContainerPage( // Create this page
      //           roomId: roomId,
      //           roomName: roomName,
      //           // ... pass other args ...
      //         ),
      //         settings: settings,
      //       );
      //     }
      //   }
      //   _logger.severe("Incorrect arguments for ${AppRoutes.addContainer}: ${settings.arguments}");
      //   return _errorRoute("Invalid arguments for Add Container page");
      // case AppRoutes.addItem:
      //   if (settings.arguments is Map<String, String?>) { // containerId might be null if not used yet
      //     final args = settings.arguments as Map<String, String?>;
      //     final containerId = args['containerId'];
      //     final containerName = args['containerName'];
      //     // ... other IDs if needed by AddItemPage ...
      //
      //     if (containerName != null) { // At least containerName should be there
      //       return MaterialPageRoute(
      //         // Assuming AddItemPage has its own Scaffold or is wrapped as needed
      //         builder: (_) => AddItemPage( // Create this page
      //           containerId: containerId,
      //           containerName: containerName,
      //           // ... pass other args ...
      //         ),
      //         settings: settings,
      //       );
      //     }
      //   }
      //   _logger.severe("Incorrect arguments for ${AppRoutes.addItem}: ${settings.arguments}");
      //   return _errorRoute("Invalid arguments for Add Item page");

      default:
        _mainLogger.warning("Unknown route: ${settings.name}");
        return _errorRoute("Page not found");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text(message)),
        );
      },
    );
  }
}

class MyHomePageWrapper extends StatefulWidget {
  final WidgetBuilder initialPageBuilder;
  final String appBarTitle;
  final bool showBackButton;
  final WidgetBuilder? floatingActionButtonBuilder;

  const MyHomePageWrapper({
    super.key,
    required this.initialPageBuilder,
    required this.appBarTitle,
    this.showBackButton = false,
    this.floatingActionButtonBuilder,
  });

  @override
  State<MyHomePageWrapper> createState() => _MyHomePageWrapperState();
}

class _MyHomePageWrapperState extends State<MyHomePageWrapper> {
  Future<void> _resetDatabaseWithSampleData() async {
    final dataService = Provider.of<IDataService>(context, listen: false);
    final imageDataService = Provider.of<IImageDataService?>(
      context,
      listen: false,
    );

    if (imageDataService == null) {
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
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'Reset ALL data to sample set? This cannot be undone.',
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
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database... Please wait.')),
      );

      final populator = SampleDataPopulator(
        dataService: dataService,
        imageDataService: imageDataService, // Pass the potentially null service
      );

      try {
        await populator.populate(); // This now handles clearing and populating
        _mainLogger.info("Sample data population successful.");
        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database has been reset with sample data.'),
            ),
          );
          // IMPORTANT: How to refresh?
          // If LocationsPage is currently visible, it needs to be rebuilt.
          // This can be complex. A simple approach might be to pop all routes and
          // push the locations route again, or use a more advanced state management
          // to signal data changes. For now, this setState might not be enough
          // if the underlying page doesn't listen to a stream that changes.
          // For a DB reset, forcing a re-fetch in LocationsPage (e.g., in didChangeDependencies
          // or via a ValueNotifier) is more robust.
          // A simple (but not always ideal) way:
          if (ModalRoute.of(context)?.settings.name == AppRoutes.locations) {
            // If we are on locations page, a simple setState might trigger its rebuild
            // if it's designed to refetch on build or didChangeDependencies.
            // More robust: LocationsPage should listen to a stream/notifier from DataService.
          }
          Navigator.of(
            context,
          ).popUntil((route) => route.isFirst); // Go back to locations
          if (ModalRoute.of(context)?.settings.name != AppRoutes.locations) {
            // If not already there
            Navigator.of(context).pushReplacementNamed(AppRoutes.locations);
          } else {
            // If already on locations, we need a way to tell LocationsPage to refresh.
            // This is where a proper ViewModel or service stream is beneficial.
            // For now, let's assume LocationsPage will refetch if it's rebuilt.
            // This setState will rebuild MyHomePageWrapper, if locations page is its child, it might also rebuild.
            setState(() {});
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle),
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                tooltip: 'Back',
              )
            : (kDebugMode
                  ? Builder(
                      builder: (BuildContext appBarContext) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Developer Options',
                          onPressed: () {
                            Scaffold.of(appBarContext).openDrawer();
                          },
                        );
                      },
                    )
                  : null),
      ),
      drawer: kDebugMode && !widget.showBackButton
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Text(
                      'Developer Options',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Reset DB with Sample Data'),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer
                      await _resetDatabaseWithSampleData();
                    },
                  ),
                ],
              ),
            )
          : null,
      body: widget.initialPageBuilder(context),
      floatingActionButton: widget.floatingActionButtonBuilder?.call(context),
    );
  }
}
