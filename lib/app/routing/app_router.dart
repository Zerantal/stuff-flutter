// lib/app/routing/app_router.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/location/pages/locations_page.dart';
import '../../features/location/pages/edit_location_page.dart';
// import '../../features/room/pages/rooms_page.dart';
// import '../../features/room/pages/edit_room_page.dart';
// import '../../features/container/pages/containers_page.dart';

import 'app_routes.dart';

class AppRouter {
  static GoRouter buildRouter({String initialLocation = '/locations'}) {
    return GoRouter(
      debugLogDiagnostics: kDebugMode,
      initialLocation: '/locations',
      routes: [
        GoRoute(
          name: AppRoutes.locations.name,
          path: AppRoutes.locations.path,
          builder: (context, state) => const LocationsPage(),
        ),
        GoRoute(
          name: AppRoutes.locationsAdd.name,
          path: AppRoutes.locationsAdd.path,
          builder: (context, state) => const EditLocationPage(),
        ),
        GoRoute(
          name: AppRoutes.locationsEdit.name,
          path: AppRoutes.locationsEdit.path,
          builder: (context, state) {
            final locationId = state.pathParameters['locationId'];
            if (locationId == null) return _errorPage('Missing Location for edit');
            return EditLocationPage(locationId: locationId);
          },
        ),
        // GoRoute(
        //   name: AppRoutes.rooms.name,
        //   path: AppRoutes.rooms.path,
        //   builder: (context, state) {
        //     final location = state.extra as Location?;
        //     if (location == null) return _errorPage('Missing Location for rooms');
        //     return RoomsPage(location: location);
        //   },
        // ),
        // GoRoute(
        //   name: AppRoutes.roomsAdd.name,
        //   path: AppRoutes.roomsAdd.path,
        // //   builder: (context, state) => EditRoomPage(),
        // ),
        // GoRoute(
        //   name: AppRoutes.roomsEdit.name,
        //   path: AppRoutes.roomsEdit.name,
        //   // builder: (context, state) {
        //   //   final roomId = state.pathParameters['roomId'];
        //   //   if (roomId == null) return _errorPage('Missing roomId for editRoom');
        //   //
        //   //   return EditRoomPage(roomId: roomId);
        //   // },
        // ),
        // GoRoute(
        //   name: AppRoutes.containers.name,
        //   path: AppRoutes.containers.path,
        //   builder: (context, state) {
        //     final room = state.extra as Room?;
        //     if (room == null) return _errorPage('Missing Room for containers');
        //     return ContainersPage(room: room);
        //   },
        // ),
        // GoRoute(
        //   name: AppRoutes.items.name,
        //   path: AppRoutes.items.path,
        //   builder: (context, state) {
        //     final args = state.extra as ItemPageArguments?;
        //     if (args == null) return _errorPage('Missing arguments for items');
        //     return ItemsPage(args: args);
        //   },
        // ),
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
