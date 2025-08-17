// lib/app/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'bootstrap.dart';
import 'injection.dart';
import 'routing/app_router.dart';
import 'theme.dart';
import '../shared/Widgets/error_display_app.dart';

Future<void> main() async {
  configureLogging();
  setupFlutterErrorHooks();

  // Keep top-level errors under control.
  runZonedGuarded(
    () async {
      // returns null if bootstrap failed and ErrorDisplayApp is shown
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
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;
    return MaterialApp.router(
      debugShowCheckedModeBanner: true,
      routerConfig: router,
      theme: buildAppTheme(),
    );
  }
}

/// Attempts to bootstrap services. On failure, shows ErrorDisplayApp and returns null.
Future<AppCore?> _safeBootstrap() async {
  try {
    return await bootstrapCore(); // initializes Hive, IDataService, IImageDataService (awaited)
  } catch (e, s) {
    // IMPORTANT: Do not depend on any Providers here—show a standalone error app.
    runApp(ErrorDisplayApp(error: e, stackTrace: s));
    return null;
  }
}
