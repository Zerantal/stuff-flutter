// lib/routing/app_routes.dart

enum AppRoutes {
  locations('/locations'),
  locationsAdd('/locations/add'),
  locationsEdit('/locations/:locationId/edit', requiredPathParams: {'locationId'}),

  rooms('/rooms/:locationId', requiredPathParams: {'locationId'}),
  roomsAdd('/rooms/:locationId/add', requiredPathParams: {'locationId'}),
  roomsEdit('/rooms/:roomId/edit', requiredPathParams: {'roomId'}),

  containers('/containers/:roomId', requiredPathParams: {'roomId'}),
  containersAdd('/containers/:roomId/add', requiredPathParams: {'roomId'}),
  containersEdit('/containers/:containerId/edit', requiredPathParams: {'containerId'}),

  // param 't' = 'room' or 'container'
  items('/items/:t/:roomOrContainerId', requiredPathParams: {':t', 'roomOrContainerId'}),
  itemsAdd('/items/:t/:roomOrContainerId/add', requiredPathParams: {':t', 'roomOrContainerId'}),
  itemsEdit('/items/:itemId/edit', requiredPathParams: {'itemId'});

  /// The actual path string for the route.
  final String path;
  final Set<String> requiredPathParams;

  /// Constant constructor for the enum.
  const AppRoutes(this.path, {this.requiredPathParams = const {}});
}
