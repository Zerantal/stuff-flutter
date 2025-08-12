// lib/app/bootstrap.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../services/contracts/data_service_interface.dart';
import '../services/impl/hive_db_data_service.dart';
import '../shared/Widgets/error_display_app.dart';

/// Expose essential singletons constructed during bootstrap.
late final EssentialServices essentialServices;

/// Public entrypoint used by main.dart to start the app after bootstrapping.
Future<void> bootstrap(Widget Function() appBuilder) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      _log.info("Flutter bindings ensured. Beginning bootstrap.");

      _setupLogging();
      _setupFlutterErrorHooks();

      try {
        // await _initHiveAndRegisterAdapters();
        final ds = await _initHiveAndGetDataService();

        essentialServices = EssentialServices(dataService: ds);
      } catch (error, stackTrace) {
        _log.severe('Fatal during core initialization. App cannot start.', error, stackTrace);
        runApp(ErrorDisplayApp(error: error, stackTrace: stackTrace));
        return;
      }

      _log.info('Core services ready. Launching UI...');
      runApp(appBuilder());
    },
    (error, stack) {
      // Last-ditch safety net for anything that escapes the zone.
      _log.severe('Uncaught zone error', error, stack);
      runApp(ErrorDisplayApp(error: error, stackTrace: stack));
    },
  );
}

/// Catch framework and platform errors.
void _setupFlutterErrorHooks() {
  FlutterError.onError = (FlutterErrorDetails details) {
    _log.severe('FlutterError', details.exception, details.stack);
  };

  // Unhandled errors coming from platform/engine layer
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _log.severe('PlatformDispatcher error', error, stack);
    // Return true to indicate we handled it (prevents default crash)
    return true;
  };
}

Future<IDataService> _initHiveAndGetDataService() async {
  _log.info('Initializing Hive...');
  await Hive.initFlutter('database');

  _log.info('Creating/initializing DataService (HiveDbDataService)...');
  final IDataService ds = HiveDbDataService();
  await ds.init();
  _log.info('DataService initialized');
  return ds;
}

/// Container for core app-wide singletons created before runApp().
class EssentialServices {
  final IDataService dataService;

  EssentialServices({required this.dataService});
}

final _log = Logger('Bootstrap');

void _setupLogging() {
  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((r) {
    // One line per field to avoid Logcat truncation issues
    debugPrint('${r.level.name.padRight(7)} ${r.loggerName}: ${r.message}');
    if (r.error != null) debugPrint('ERROR: ${r.error}');
    if (r.stackTrace != null) debugPrint('STACKTRACE:\n${r.stackTrace}');
  });
}
