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

import 'routing/app_routes.dart';
import 'pages/locations_page.dart';
import 'pages/edit_location_page.dart';
import 'pages/containers_page.dart';
import 'pages/items_page.dart';
import 'pages/rooms_page.dart';
import 'pages/edit_room_page.dart';
import 'models/location_model.dart';
import 'models/item_page_arguments.dart';
import 'models/room_model.dart';
import 'services/impl/hive_db_data_service.dart';
import 'services/data_service_interface.dart';
import 'services/impl/geolocator_location_service.dart';
import 'services/location_service_interface.dart';
import 'services/impl/local_app_image_data_service.dart';
import 'services/impl/flutter_image_picker_service.dart';
import 'services/image_picker_service_interface.dart';
import 'services/temporary_file_service_interface.dart';
import 'services/impl/path_provider_temporary_file_service.dart';
import 'widgets/error_display_app.dart';

final _mainLogger = Logger('AppInitializer');

const MethodChannel _nativeLogChannel = MethodChannel('com.example.stuff/log');

Future<void> _sendToNativeLog(LogRecord record) async {
  if (!kDebugMode && record.level < Level.SEVERE) {
    // TODO: Implement crash reporting (e.g., Sentry, Firebase Crashlytics)
    return;
  }
  try {
    // Fallback if platform channel fails
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
  Logger.root.level = Level.ALL;
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
  });
}

Future<void> _initializeHive() async {
  _mainLogger.info("Initializing Hive and registering adapters...");
  try {
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);

    // Register adapters
    Hive.registerAdapter(LocationAdapter());
    _mainLogger.finer(
      "LocationAdapter registered (typeId: ${LocationAdapter().typeId}).",
    );

    Hive.registerAdapter(RoomAdapter());
    _mainLogger.finer(
      "RoomAdapter registered (typeId: ${RoomAdapter().typeId}).",
    );

    _mainLogger.info(
      "Hive initialization and adapter registration completed successfully.",
    );
  } catch (e, s) {
    _mainLogger.severe(
      "Error during Hive initialization or adapter registration",
      e,
      s,
    );
    rethrow;
  }
}

Future<IDataService> _initializeDataService() async {
  _mainLogger.info("Initializing DataService...");
  final IDataService dataService = HiveDbDataService();
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
    return null;
  }
}

/// Data class to hold essential initialized services.
class EssentialServices {
  final IDataService dataService;
  EssentialServices({required this.dataService});
}

/// Initializes core application services that MUST be available before the app runs.
Future<EssentialServices> _initializeAppServices() async {
  _mainLogger.info("Starting core application services initialization...");
  await _configureLogging();
  await _initializeHive();
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
        runApp(ErrorDisplayApp(error: error, stackTrace: stackTrace));
        return;
      }

      _mainLogger.info(
        "Essential services obtained. Setting up providers and running UI.",
      );

      runApp(
        MultiProvider(
          providers: [
            Provider<IDataService>.value(value: essentialServices.dataService),
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
              create: (context) => _createLocalAppImageDataService(),
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
    _mainLogger.info(
      "Navigating to route: ${settings.name} with arguments: ${settings.arguments}",
    );

    switch (settings.name) {
      case AppRoutes.locations:
        return MaterialPageRoute(
          builder: (_) => const LocationsPage(),
          settings: settings,
        );

      case AppRoutes.addLocation:
        return MaterialPageRoute(
          builder: (_) => const EditLocationPage(),
          settings: settings,
        );

      case AppRoutes.editLocation:
        if (settings.arguments is Location) {
          final location = settings.arguments as Location;
          return MaterialPageRoute(
            builder: (_) => EditLocationPage(initialLocation: location),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.editLocation}: Expected Location, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Edit Location page");

      case AppRoutes.rooms:
        if (settings.arguments is Location) {
          final location = settings.arguments as Location;
          return MaterialPageRoute(
            builder: (_) => RoomsPage(location: location),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.rooms}: Expected Location, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Rooms page");

      case AppRoutes.addRoom:
        if (settings.arguments is Location) {
          final parentLocation = settings.arguments as Location;
          return MaterialPageRoute(
            builder: (_) => EditRoomPage(parentLocation: parentLocation),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.addRoom}: Expected Location, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Add Room page");

      case AppRoutes.editRoom:
        if (settings.arguments is Map<String, dynamic>) {
          final args = settings.arguments as Map<String, dynamic>;
          final room = args['room'] as Room?;
          final parentLocation = args['parentLocation'] as Location?;

          if (room != null && parentLocation != null) {
            return MaterialPageRoute(
              builder: (_) => EditRoomPage(
                initialRoom: room,
                parentLocation: parentLocation,
              ),
            );
          } else {
            _mainLogger.severe(
              "Missing 'room' or 'parentLocation' in arguments for ${AppRoutes.editRoom}",
            );
            return _errorRoute("Invalid arguments for Edit Room page");
          }
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.editRoom}: Expected {'room': Room, 'parentLocation': Location}, got ${settings.arguments}",
        );
        return _errorRoute("Invalid arguments for Edit Room page");

      case AppRoutes.containers:
        if (settings.arguments is Room) {
          final roomData = settings.arguments as Room;
          return MaterialPageRoute(
            builder: (_) => ContainersPage(room: roomData),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.containers}: Expected Room, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Containers page");

      case AppRoutes.items:
        if (settings.arguments is ItemPageArguments) {
          final itemArgs = settings.arguments as ItemPageArguments;
          return MaterialPageRoute(
            builder: (_) => ItemsPage(args: itemArgs),
            settings: settings,
          );
        }
        _mainLogger.severe(
          "Incorrect arguments for ${AppRoutes.items}: Expected ItemPageArguments, got ${settings.arguments?.runtimeType}",
        );
        return _errorRoute("Invalid arguments for Items page");

      default:
        _mainLogger.warning("Unknown route: ${settings.name}");
        return _errorRoute("Page not found (404)");
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        );
      },
    );
  }
}
