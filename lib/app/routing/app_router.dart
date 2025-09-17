// lib/app/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/container/pages/edit_container_page.dart';
import '../../features/container/viewmodels/edit_container_view_model.dart';
import '../../features/contents/pages/contents_page.dart';
import '../../features/contents/viewmodels/contents_view_model.dart';
import '../../features/dev_tools/pages/database_inspector_page.dart';
import '../../features/dev_tools/pages/sample_data_options_page.dart';
import '../../features/item/pages/item_details_page.dart';
import '../../features/item/pages/item_details_wrapper.dart';
import '../../features/item/viewmodels/item_details_view_model.dart';
import '../../features/location/pages/locations_page.dart';
import '../../features/location/pages/edit_location_page.dart';
import '../../features/location/viewmodels/edit_location_view_model.dart';
import '../../features/location/viewmodels/locations_view_model.dart';
import '../../features/room/pages/edit_room_page.dart';
import '../../features/room/pages/rooms_page.dart';

import '../../features/room/viewmodels/edit_room_view_model.dart';
import '../../features/room/viewmodels/rooms_view_model.dart';
import '../theme.dart';
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
  static final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'root',
  );

  static GoRouter buildRouter({String? initialLocation}) {
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
                // ────────────────────────── Locations ──────────────────────────
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
                  name: AppRoutes.locationAdd.name,
                  path: AppRoutes.locationAdd.path,
                  builder: (context, state) => ChangeNotifierProvider(
                    key: state.pageKey,
                    create: (_) => EditLocationViewModel.forNew(context),
                    child: const EditLocationPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.locationEdit.name,
                  path: AppRoutes.locationEdit.path,
                  builder: (context, state) {
                    final locationId = state.pathParameters['locationId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => EditLocationViewModel.forEdit(context, locationId: locationId),
                      child: EditLocationPage(locationId: locationId),
                    );
                  },
                ),
                // ──────────────────────────── Rooms ────────────────────────────
                GoRoute(
                  name: AppRoutes.roomsForLocation.name,
                  path: AppRoutes.roomsForLocation.path,
                  builder: (context, state) {
                    final locationName = state.extra as String?;
                    final locationId = state.pathParameters['locationId']!;
                    return Provider<RoomsViewModel>(
                      key: state.pageKey,
                      create: (ctx) => RoomsViewModel.forLocation(ctx, locationId, locationName),
                      child: const RoomsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.roomAdd.name,
                  path: AppRoutes.roomAdd.path,
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
                  name: AppRoutes.roomEdit.name,
                  path: AppRoutes.roomEdit.path,
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
                // ───────────────────────── Containers ──────────────────────────
                GoRoute(
                  name: AppRoutes.containerAddToRoom.name,
                  path: AppRoutes.containerAddToRoom.path,
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => EditContainerViewModel.forNew(context, roomId: roomId),
                      child: const EditContainerPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.containerAddToContainer.name,
                  path: AppRoutes.containerAddToContainer.path,
                  builder: (context, state) {
                    final parentContainerId = state.pathParameters['containerId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => EditContainerViewModel.forNew(
                        context,
                        parentContainerId: parentContainerId,
                      ),
                      child: const EditContainerPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.containerEdit.name,
                  path: AppRoutes.containerEdit.path,
                  builder: (context, state) {
                    final containerId = state.pathParameters['containerId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) =>
                          EditContainerViewModel.forEdit(context, containerId: containerId),
                      child: EditContainerPage(containerId: containerId),
                    );
                  },
                ),

                // ──────────────────────────── Items ────────────────────────────
                GoRoute(
                  name: AppRoutes.itemView.name,
                  path: AppRoutes.itemView.path,
                  pageBuilder: (context, state) {
                    final itemId = state.pathParameters['itemId']!;
                    return MaterialPage(
                      key: ValueKey('item_page_$itemId'), // stable across view/edit
                      child: ItemDetailsWrapper(itemId: itemId, editable: false),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemEdit.name,
                  path: AppRoutes.itemEdit.path,
                  pageBuilder: (context, state) {
                    final itemId = state.pathParameters['itemId']!;
                    return MaterialPage(
                      key: ValueKey('item_page_$itemId'), // same key, same element
                      child: ItemDetailsWrapper(itemId: itemId, editable: true),
                    );
                  },
                ),

                GoRoute(
                  name: AppRoutes.itemAddToRoom.name,
                  path: AppRoutes.itemAddToRoom.path,
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => ItemDetailsViewModel.forNew(context, roomId: roomId),
                      child: const ItemDetailsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemAddToContainer.name,
                  path: AppRoutes.itemAddToContainer.path,
                  builder: (context, state) {
                    final containerId = state.pathParameters['containerId']!;
                    return ChangeNotifierProvider(
                      key: state.pageKey,
                      create: (_) => ItemDetailsViewModel.forNew(context, containerId: containerId),
                      child: const ItemDetailsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemViewInRoomAlias.name,
                  path: AppRoutes.itemViewInRoomAlias.path,
                  redirect: (context, state) {
                    return AppRoutes.itemView.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemEditInRoomAlias.name,
                  path: AppRoutes.itemEditInRoomAlias.path,
                  redirect: (context, state) {
                    return AppRoutes.itemEdit.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemViewInContainerAlias.name,
                  path: AppRoutes.itemViewInContainerAlias.path,
                  redirect: (context, state) {
                    return AppRoutes.itemView.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.itemEditInContainerAlias.name,
                  path: AppRoutes.itemEditInContainerAlias.path,
                  redirect: (context, state) {
                    return AppRoutes.itemEdit.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),

                // ────────────────────────── Contents ───────────────────────────
                GoRoute(
                  name: AppRoutes.allContents.name,
                  path: AppRoutes.allContents.path,
                  builder: (context, state) => Provider<ContentsViewModel>(
                    key: state.pageKey, // recreate when params change
                    create: (ctx) =>
                        ContentsVmFactory.fromContext(ctx, scope: const ContentsScope.all()),
                    child: const ContentsPage(),
                  ),
                ),
                GoRoute(
                  name: AppRoutes.locationContents.name,
                  path: AppRoutes.locationContents.path,
                  builder: (context, state) {
                    final locationId = state.pathParameters['locationId']!;
                    return Provider<ContentsViewModel>(
                      key: state.pageKey, // recreate when params change
                      create: (ctx) => ContentsVmFactory.fromContext(
                        ctx,
                        scope: ContentsScope.location(locationId),
                      ),
                      child: const ContentsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.roomContents.name,
                  path: AppRoutes.roomContents.path,
                  builder: (context, state) {
                    final roomId = state.pathParameters['roomId']!;
                    return Provider<ContentsViewModel>(
                      key: state.pageKey, // recreate when params change
                      create: (ctx) =>
                          ContentsVmFactory.fromContext(ctx, scope: ContentsScope.room(roomId)),
                      child: const ContentsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.containerContents.name,
                  path: AppRoutes.containerContents.path,
                  builder: (context, state) {
                    final containerId = state.pathParameters['containerId']!;
                    return Provider<ContentsViewModel>(
                      key: state.pageKey, // recreate when params change
                      create: (ctx) => ContentsVmFactory.fromContext(
                        ctx,
                        scope: ContentsScope.container(containerId),
                      ),
                      child: const ContentsPage(),
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.roomContentsAlias.name,
                  path: AppRoutes.roomContentsAlias.path,
                  redirect: (ctx, state) {
                    return AppRoutes.roomContents.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
                GoRoute(
                  name: AppRoutes.containerContentsAlias.name,
                  path: AppRoutes.containerContentsAlias.path,
                  redirect: (ctx, state) {
                    return AppRoutes.containerContents.toUrlString(
                      pathParams: state.pathParameters,
                      queryParams: state.uri.queryParameters,
                    );
                  },
                ),
              ],
            ),
            // Branch 1: Developer tools
            StatefulShellBranch(
              navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'devToolsBranch'),
              routes: <RouteBase>[
                // Debug
                GoRoute(
                  name: AppRoutes.debugDbInspector.name,
                  path: AppRoutes.debugDbInspector.path,
                  builder: (c, s) => const DatabaseInspectorPage(),
                ),
                GoRoute(
                  name: AppRoutes.debugSampleDbRandomiser.name,
                  path: AppRoutes.debugSampleDbRandomiser.path,
                  builder: (c, s) => const SampleDataOptionsPage(),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
