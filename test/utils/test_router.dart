// test/utils/test_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stuff/app/routing/app_routes.dart';

/// A simple page used for tests. Each route gets a stable key.
class _RouteStubPage extends StatelessWidget {
  const _RouteStubPage(this.routeName, this.state);
  final String routeName;
  final GoRouterState state;

  @override
  Widget build(BuildContext context) {
    // Helpful text to assert on.
    final params = {
      'path': state.matchedLocation,
      'pathParams': state.pathParameters,
      'queryParams': state.uri.queryParameters,
    };
    return Scaffold(
      key: ValueKey('route_$routeName'),
      body: Center(child: Text('route:$routeName\n$params', textAlign: TextAlign.center)),
    );
  }
}

/// Build a GoRouter for widget tests:
/// - mounts [home] at '/';
/// - auto-generates routes for every value in [AppRoutes];
/// - attaches [observers] to the router's navigator.
GoRouter makeTestRouter({
  required Widget home,
  List<NavigatorObserver> observers = const [],
  String initialLocation = '/',
}) {
  // One explicit home route at '/'
  final List<RouteBase> routes = <RouteBase>[
    GoRoute(path: '/', name: 'home', builder: (ctx, st) => home),
    // Generate one GoRoute per AppRoutes enum value
    ...AppRoutes.values.map((r) {
      return GoRoute(
        path: r.path,
        name: r.name, // e.g., 'locationsAdd'
        builder: (ctx, st) => _RouteStubPage(r.name, st),
      );
    }),
  ];

  return GoRouter(
    initialLocation: initialLocation,
    routes: routes,
    observers: observers, // attach test NavigatorObservers here
  );
}
