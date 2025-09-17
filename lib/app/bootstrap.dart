// lib/app/bootstrap.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../data/drift/open_db.dart';
import '../services/contracts/data_service_interface.dart';
import '../services/impl/drift_data_service.dart';
import '../services/contracts/image_data_service_interface.dart';
import '../services/impl/local_image_data_service.dart';
import '../shared/widgets/runtime_error_page.dart';
import 'main.dart';
import 'theme.dart';

final _log = Logger('Bootstrap');

/// Holds fully initialized core services.
class AppCore {
  final IDataService dataService;
  final IImageDataService imageDataService;
  AppCore({required this.dataService, required this.imageDataService});
}

/// Configure logging once, early.
void configureLogging() {
  Logger.root.level = kReleaseMode ? Level.INFO : Level.ALL;
  Logger.root.onRecord.listen((r) {
    // One line per field to avoid Logcat truncation issues
    debugPrint('${r.level.name.padRight(7)} ${r.loggerName}: ${r.message}');
    if (r.error != null) debugPrint('ERROR: ${r.error}');
    if (r.stackTrace != null) debugPrint('STACKTRACE:\n${r.stackTrace}');
  });
}

Future<IDataService> buildDataService() async {
  final db = await openAppDatabase();
  final svc = DriftDataService(db);
  await svc.init();
  return svc;
}

/// DataService + ImageDataService in order.
/// Returns instances that are READY to use.
Future<AppCore> bootstrapCore() async {
  final dataService = await buildDataService();

  _log.info('Creating/initializing LocalImageDataService...');
  final images = LocalImageDataService();
  await images.init();
  _log.info('ImageDataService initialized');

  return AppCore(dataService: dataService, imageDataService: images);
}

/// Restart handler: re-bootstrap and relaunch the app.
Future<void> onRestart() async {
  try {
    final core = await bootstrapCore();
    launchApp(core);
  } catch (e, s) {
    await Sentry.captureException(e, stackTrace: s);
    runApp(RuntimeErrorPage(error: e, stackTrace: s));
  }
}

/// Catch framework and platform errors.
void setupFlutterErrorHooks() {
  FlutterError.onError = (FlutterErrorDetails details) {
    Logger('FlutterError').severe(details.exceptionAsString(), details.exception, details.stack);

    FlutterError.presentError(details);

    // Auto-report to Sentry
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildAppTheme(),
      home: RuntimeErrorPage(
        error: details.exception,
        stackTrace: details.stack,
        onRestart: onRestart,
      ),
    );
  };

  // Unhandled errors coming from platform/engine layer
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _log.severe('PlatformDispatcher error', error, stack);
    // Return true to indicate we handled it (prevents default crash)
    return true;
  };
}
