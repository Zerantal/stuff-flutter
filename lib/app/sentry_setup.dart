// lib/app/sentry_setup.dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Configures Sentry with useful device/app context.
class SentrySetup {
  /// Call during bootstrap, before runApp.
  static void configureBootstrapScope() {
    Sentry.configureScope((scope) {
      scope.setTag('platform', defaultTargetPlatform.name);
      scope.setTag('os', Platform.operatingSystem);
      scope.setTag('osVersion', Platform.operatingSystemVersion);
    });
  }

  /// Call after the widget tree is built to add UI-related context
  /// (e.g., theme brightness, locale).
  static void configureUiScope(GlobalKey<NavigatorState> navigatorKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx == null) return;

      final theme = Theme.of(ctx);
      final locale = Localizations.maybeLocaleOf(ctx);

      Sentry.configureScope((scope) {
        scope.setTag('brightness', theme.brightness.name);
        if (locale != null) {
          scope.setTag('locale', locale.toLanguageTag());
        }
      });
    });
  }
}
