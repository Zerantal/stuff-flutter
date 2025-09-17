// lib/app/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:logging/logging.dart';
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
      WidgetsFlutterBinding.ensureInitialized();

      // Configure bootstrap-safe tags (no context needed)
      SentrySetup.configureBootstrapScope();

      try {
        final core = await bootstrapCore();

        launchApp(core);
      } catch (e, s) {
        // Report to Sentry immediately
        final eventId = await Sentry.captureException(e, stackTrace: s);

        // Show standalone error UI with *real* error + stacktrace
        runApp(ErrorDisplayApp(error: e, stackTrace: s, sentryId: eventId));
      }
    },
  );
}

/// Public method to launch the app with given [AppCore].
/// Can also be used by restart handlers.
void launchApp(AppCore core) {
  runApp(
    MultiProvider(
      providers: buildGlobalProviders(
        dataService: core.dataService,
        imageDataService: core.imageDataService,
      ),
      child: const _App(),
    ),
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
