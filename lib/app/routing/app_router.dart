// lib/app/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/container/pages/edit_container_page.dart';
import '../../features/contents/pages/contents_page.dart';
import '../../features/dev_tools/pages/database_inspector_page.dart';
import '../../features/item/pages/edit_item_page.dart';
import '../../features/location/pages/locations_page.dart';
import '../../features/location/pages/edit_location_page.dart';
import '../../features/location/viewmodels/edit_location_view_model.dart';
import '../../features/location/viewmodels/locations_view_model.dart';
import '../../features/room/pages/edit_room_page.dart';
import '../../features/room/pages/rooms_page.dart';

import '../../features/room/viewmodels/edit_room_view_model.dart';
import '../../features/room/viewmodels/rooms_view_model.dart';
import 'app_routes_ext.dart';
import 'app_routes.dart';

class RootAppShell extends StatelessWidget {
  const RootAppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: navigationShell);
  }
}

class AppRouter {
  static GoRouter buildRouter({String? initialLocation}) {
    final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
      debugLabel: 'root',
    );

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      debugLogDiagnostics: kDebugMode,
      initialLocation: initialLocation ?? AppRoutes.locations.path,
      routes: [
        StatefulShellRoute.indexedStack(
          builder:
              (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
                return RootAppShell(navigationShell: navigationShell);
              },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                // --- Locations ---
                GoRoute(
                  name: AppRoutes.locations.name,
                  path: AppRoutes.locations.path,
                  builder: (context, state) => Provider<LocationsViewModel>(
                    key: state.pageKey, // recreate when params change
                    create: (ctx) => LocationsViewModel.create(ctx),
                    child: const LocationsPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.locationsAdd.name,
                  path: AppRoutes.locationsAdd.path,
                  builder: (context, state) => ChangeNotifierProvider(
                    key: state.pageKey,
                    create: (_) => EditLocationViewModel.forNew(context),
                    child: const EditLocationPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.locationsEdit.name,
                  path: AppRoutes.locationsEdit.path,
                  builder: (context, state) {
                    final locationId = state.pathParameters['locationId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => EditLocationViewModel.forEdit(context, locationId: locationId),
                      child: EditLocationPage(locationId: locationId),
                    );
                  },
                ),
                // --- Rooms ---
                GoRoute(
                  name: AppRoutes.rooms.name,
                  path: AppRoutes.rooms.path,
                  builder: (context, state) => Provider<RoomsViewModel>(
                    key: state.pageKey,
                    create: (ctx) =>
                        RoomsViewModel.forLocation(ctx, state.pathParameters['locationId']!),
                    child: const RoomsPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.roomsAdd.name,
                  path: AppRoutes.roomsAdd.path,
                  builder: (context, state) => ChangeNotifierProvider(
                    key: state.pageKey,
                    create: (_) => EditRoomViewModel.forNew(
                      context,
                      locationId: state.pathParameters['locationId']!,
                    ),
                    child: const EditRoomPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.roomsEdit.name,
                  path: AppRoutes.roomsEdit.path,
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    final locationId = state.pathParameters['locationId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => EditRoomViewModel.forEdit(
                        context,
                        locationId: locationId,
                        roomId: roomId,
                      ),
                      child: EditRoomPage(roomId: roomId),
                    );
                  },
                ),
                // --- Containers ---
                GoRoute(
                  name: AppRoutes.containersAdd.name,
                  path: AppRoutes.containersAdd.path,
                  builder: (c, s) => EditContainerPage(
                    locationId: s.pathParameters['locationId']!,
                    roomId: s.pathParameters['roomId']!,
                  ),
                ),
                GoRoute(
                  name: AppRoutes.containersEdit.name,
                  path: AppRoutes.containersEdit.path,
                  builder: (c, s) => EditContainerPage(
                    locationId: s.pathParameters['locationId']!,
                    roomId: s.pathParameters['roomId']!,
                    containerId: s.pathParameters['containerId']!,
                  ),
                ),

                // --- Items ---
                GoRoute(
                  name: 'itemsAddToContainer',
                  path: '/locations/:locationId/rooms/:roomId/containers/:containerId/items/add',
                  builder: (c, s) => ItemDetailsPage.addToContainer(
                    locationId: s.pathParameters['locationId']!,
                    roomId: s.pathParameters['roomId']!,
                    containerId: s.pathParameters['containerId']!,
                  ),
                ),
                GoRoute(
                  name: 'itemsAddToRoom',
                  path: '/locations/:locationId/rooms/:roomId/items/add',
                  builder: (c, s) => ItemDetailsPage.addToRoom(
                    locationId: s.pathParameters['locationId']!,
                    roomId: s.pathParameters['roomId']!,
                  ),
                ),
                GoRoute(
                  name: 'itemView',
                  path: '/items/:itemId',
                  builder: (c, s) => ItemDetailsPage.view(itemId: s.pathParameters['itemId']!),
                ),
                GoRoute(
                  name: 'itemEdit',
                  path: '/items/:itemId/edit',
                  builder: (c, s) => ItemDetailsPage.edit(itemId: s.pathParameters['itemId']!),
                ),
                GoRoute(
                  name: AppRoutes.itemViewInRoom.name,
                  path: AppRoutes.itemViewInRoom.path,
                  redirect: (context, state) {
                    return AppRoutes.itemView.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemEditInRoom.name,
                  path: AppRoutes.itemEditInRoom.path,
                  redirect: (context, state) {
                    return AppRoutes.itemEdit.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemViewInContainer.name,
                  path: AppRoutes.itemViewInContainer.path,
                  redirect: (context, state) {
                    return AppRoutes.itemView.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemEditInContainer.name,
                  path: AppRoutes.itemEditInContainer.path,
                  redirect: (context, state) {
                    return AppRoutes.itemEdit.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),

                // --- Contents (scoped views) ---
                GoRoute(
                  name: AppRoutes.allContents.name,
                  path: AppRoutes.allContents.path,
                  builder: (c, s) => const ContentsPage(scope: ContentsScope.all()),
                ),
                GoRoute(
                  name: AppRoutes.locationContents.name,
                  path: AppRoutes.locationContents.path,
                  builder: (c, s) =>
                      ContentsPage(scope: ContentsScope.location(s.pathParameters['locationId']!)),
                ),
                GoRoute(
                  name: AppRoutes.roomContents.name,
                  path: AppRoutes.roomContents.path,
                  builder: (c, s) => ContentsPage(
                    scope: ContentsScope.room(
                      s.pathParameters['locationId']!,
                      s.pathParameters['roomId']!,
                    ),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.containerContents.name,
                  path: AppRoutes.containerContents.path,
                  builder: (c, s) => ContentsPage(
                    scope: ContentsScope.container(
                      s.pathParameters['locationId']!,
                      s.pathParameters['roomId']!,
                      s.pathParameters['containerId']!,
                    ),
                  ),
                ),
              ],
            ),
            // Branch 1: Developer tools
            StatefulShellBranch(
              // navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'devToolsBranch'), // Optional
              routes: <RouteBase>[
                // Debug
                GoRoute(
                  name: AppRoutes.debugDbInspector.name,
                  path: AppRoutes.debugDbInspector.path,
                  builder: (c, s) => const DatabaseInspectorPage(),
                ),
              ],
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) =>
          _errorPage(state.error?.toString() ?? 'Unknown navigation error'),
    );
  }

  static final GoRouter router = buildRouter();

  static Widget _errorPage(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
