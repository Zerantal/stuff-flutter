// lib/app/routing/app_routes.dart

enum AppRoutes {
  // ────────────────────────── Locations ──────────────────────────
  locations('/locations'),
  locationAdd('/locations/add'),
  locationEdit('/locations/:locationId/edit'),

  // ──────────────────────────── Rooms ────────────────────────────
  roomsForLocation('/locations/:locationId/rooms'), // list rooms under location
  roomAdd('/locations/:locationId/rooms/add'),
  roomEdit('/locations/:locationId/rooms/:roomId/edit'),

  // ───────────────────────── Containers ──────────────────────────
  // canonical container routes
  containerAddToRoom('/rooms/:roomId/containers/add'),
  containerAddToContainer('/containers/:containerId/containers/add'),
  containerEdit('/containers/:containerId/edit'),

  //aliases
  containerAddToRoomAlias('/locations/:locationId/rooms/:roomId/containers/add'),
  containerAddToContainerAlias(
    '/locations/:locationId/rooms/:roomId/containers/:parentContainerId/containers/add',
  ),
  containerEditInRoomAlias('/locations/:locationId/rooms/:roomId/containers/:containerId/edit'),
  containerEditInContainerAlias(
    '/locations/:locationId/rooms/:roomId/containers/:parentContainerId/containers/:containerId/edit',
  ),

  // ──────────────────────────── Items ────────────────────────────
  // Canonical item routes
  itemView('/items/:itemId'),
  itemEdit('/items/:itemId/edit'),
  itemAddToRoom('/rooms/:roomId/items/add'),
  itemAddToContainer('/containers/:containerId/items/add'),

  // Aliases (keep for UX/back-compat)
  itemViewInRoomAlias('/locations/:locationId/rooms/:roomId/items/:itemId'),
  itemEditInRoomAlias('/locations/:locationId/rooms/:roomId/items/:itemId/edit'),
  itemViewInContainerAlias(
    '/locations/:locationId/rooms/:roomId/containers/:containerId/items/:itemId',
  ),
  itemEditInContainerAlias(
    '/locations/:locationId/rooms/:roomId/containers/:containerId/items/:itemId/edit',
  ),

  // ────────────────────────── Contents ───────────────────────────
  // Canonical contents routes
  allContents('/contents'),
  locationContents('/locations/:locationId/contents'),
  roomContents('/rooms/:roomId/contents'),
  containerContents('/containers/:containerId/contents'),

  // Aliases (nested readability / back-compat)
  roomContentsAlias('/locations/:locationId/rooms/:roomId/contents'),
  containerContentsAlias('/locations/:locationId/rooms/:roomId/containers/:containerId/contents'),

  // ─────────────────────────── Debug ────────────────────────────
  debugDbInspector('/debug/db_inspector'),
  debugSampleDbRandomiser('/debug/sample_db_randomiser');

  final String path;
  const AppRoutes(this.path);
}
