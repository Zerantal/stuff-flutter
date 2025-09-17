// lib/app/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'bootstrap.dart';
import 'injection.dart';
import 'routing/app_router.dart';
import 'sentry_setup.dart';
import 'theme.dart';
import '../shared/widgets/error_display_app.dart';

Future<void> main() async {
  configureLogging();
  setupFlutterErrorHooks();

  // Initialize Sentry before bootstrapping
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://776b4b5f87125acfdea181145350f88d@o4510028089065472.ingest.de.sentry.io/4510028090769488';
      // options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      // Use runZonedGuarded to catch any unhandled Dart errors
      runZonedGuarded(
        () async {
          // Configure bootstrap-safe tags (no context needed)
          SentrySetup.configureBootstrapScope();

          final core = await _safeBootstrap();
          if (core == null) return;

          runApp(
            MultiProvider(
              providers: buildGlobalProviders(
                dataService: core.dataService,
                imageDataService: core.imageDataService,
              ),
              child: const _App(),
            ),
          );
        },
        (error, stack) {
          Logger('Zone').severe('Uncaught zone error', error, stack);
        },
      );
    },
  );
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.buildRouter();

    // Add UI-related tags once the app is running
    SentrySetup.configureUiScope(AppRouter.rootNavigatorKey);

    return MaterialApp.router(
      restorationScopeId: 'root',
      debugShowCheckedModeBanner: true,
      routerConfig: router,
      theme: AppTheme.buildAppTheme(),
    );
  }
}

/// Attempts to bootstrap services. On failure, shows ErrorDisplayApp and reports to Sentry.
Future<AppCore?> _safeBootstrap() async {
  try {
    return await bootstrapCore(); // your service init (Hive, IDataService, etc.)
  } catch (e, s) {
    // Report to Sentry immediately
    await Sentry.captureException(e, stackTrace: s);

    // Show standalone error UI
    runApp(ErrorDisplayApp(error: e, stackTrace: s));

    return null;
  }
}
