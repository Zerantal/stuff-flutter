// lib/app/routing/app_routes.dart

enum AppRoutes {
  locations('/locations'),
  locationsAdd('/locations/add'),
  locationsEdit('/locations/:locationId/edit'),

  rooms('/locations/:locationId/rooms'),
  roomsAdd('/locations/:locationId/rooms/add'),
  roomsEdit('/locations/:locationId/rooms/:roomId/edit'),

  containersAdd('/locations/:locationId/rooms/:roomId/containers/add'),
  containersEdit('/locations/:locationId/rooms/:roomId/containers/:containerId/edit'),

  itemsAddToContainer('/locations/:locationId/rooms/:roomId/containers/:containerId/items/add'),
  itemsAddToRoom('/locations/:locationId/rooms/:roomId/items/add'),
  itemViewInRoom('/locations/:locationId/rooms/:roomId/items/:itemId'), // alias
  itemEditInRoom('/locations/:locationId/rooms/:roomId/items/:itemId/edit'), // alias
  itemViewInContainer(
    '/locations/:locationId/rooms/:roomId/containers/:containerId/items/:itemId',
  ), //alias
  itemEditInContainer(
    '/locations/:locationId/rooms/:roomId/containers/:containerId/items/:itemId/edit',
  ), //alias
  itemView('/items/:itemId'), // Canonical route
  itemEdit('/items/:itemId/edit'), // Canonical route

  allContents('/contents'),
  locationContents('/locations/:locationId/contents'),
  roomContents('/locations/:locationId/rooms/:roomId/contents'),
  containerContents('/locations/:locationId/rooms/:roomId/containers/:containerId/contents'),

  // debug routes
  debugDbInspector('/debug/db_inspector');

  /// The actual path string for the route.
  final String path;

  /// Constant constructor for the enum.
  const AppRoutes(this.path);
}
