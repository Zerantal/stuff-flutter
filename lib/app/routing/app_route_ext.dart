// lib/routing/app_route_ext.dart
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

extension AppRouteNav on AppRoutes {
  void _check(Map<String, String> pathParams) {
    final missing = requiredPathParams.difference(pathParams.keys.toSet());
    if (missing.isNotEmpty) {
      throw ArgumentError('Missing path params for $name: ${missing.join(", ")}');
    }
  }

  // Build URL without context (useful in tests or share links)
  String format({
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    _check(pathParams);
    var p = path;
    pathParams.forEach((k, v) => p = p.replaceAll(':$k', Uri.encodeComponent(v)));
    if (queryParams.isNotEmpty) {
      p += '?${Uri(queryParameters: queryParams).query}';
    }
    return p;
  }

  // Navigation wrappers (prefer names to decouple from raw paths)
  void go(
    BuildContext context, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    _check(pathParams);
    context.goNamed(name, pathParameters: pathParams, queryParameters: queryParams, extra: extra);
  }

  void push(
    BuildContext context, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
    Object? extra,
  }) {
    _check(pathParams);
    context.pushNamed(name, pathParameters: pathParams, queryParameters: queryParams, extra: extra);
  }

  // Build a location via router (validates & respects redirections)
  String location(
    BuildContext context, {
    Map<String, String> pathParams = const {},
    Map<String, String> queryParams = const {},
  }) {
    _check(pathParams);
    return GoRouter.of(
      context,
    ).namedLocation(name, pathParameters: pathParams, queryParameters: queryParams);
  }
}
