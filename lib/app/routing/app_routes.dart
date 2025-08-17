// lib/routing/app_routes.dart

// lib/app/routing/app_routes.dart
enum AppRoutes {
  locations('/locations'),
  locationsAdd('/locations/add'),
  locationsEdit('/locations/:locationId/edit'),

  rooms('/rooms/:locationId'),
  roomsAdd('/rooms/:locationId/add'),
  roomsEdit('/rooms/:roomId/edit'),

  containers('/containers/:roomId'),
  containersAdd('/containers/:roomId/add'),
  containersEdit('/containers/:containerId/edit'),

  // param 't' = type ('room' or 'container')
  items('/items/:t/:roomOrContainerId'),
  itemsAdd('/items/:t/:roomOrContainerId/add'),
  itemsEdit('/items/:itemId/edit');

  /// The actual path string for the route.
  final String path;

  /// Constant constructor for the enum.
  const AppRoutes(this.path);
}
