// lib/viewmodels/rooms_view_model.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../domain/models/location_model.dart';
import '../../../domain/models/room_model.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_route_ext.dart';

final Logger _logger = Logger('RoomsViewModel');

class RoomsViewModel extends ChangeNotifier {
  final IDataService _dataService;
  final Location _currentLocation; // The current location for which to display rooms
  Location get currentLocation => _currentLocation;

  // Constructor
  RoomsViewModel({required IDataService dataService, required Location location})
    : _dataService = dataService,
      _currentLocation = location {
    _logger.info(
      "RoomsViewModel created for location: ${_currentLocation.name} (ID: ${_currentLocation.id})",
    );
  }

  // --- Private Methods ---

  // Action: Navigate to add a new room
  void navigateToAddRoom(BuildContext context) {
    _logger.info("Navigating to add new room for location: ${_currentLocation.name}");

    AppRoutes.roomsAdd.go(context, pathParams: {'locationId': _currentLocation.id});
  }

  // Action: Navigate to edit an existing room
  void navigateToEditRoom(BuildContext context, Room room) {
    _logger.info("Navigating to edit room: ${room.name}");

    AppRoutes.roomsEdit.go(context, pathParams: {'roomId': room.id});
  }

  // Action: Navigate to view contents of a room (e.g., items within the room)
  void navigateToViewRoomContents(BuildContext context, Room room) {
    _logger.info("Navigating to view contents for room: ${room.name}");

    AppRoutes.containers.go(context, pathParams: {'roomId': room.id});
  }

  // Action: Delete a room
  Future<void> deleteRoom(String roomId, String roomName) async {
    _logger.info("ViewModel attempting to delete room: $roomId - $roomName");
    try {
      await _dataService.deleteRoom(roomId);
      _logger.info("Room $roomId ($roomName) deleted successfully via DataService.");
    } catch (e, s) {
      _logger.severe("ViewModel: Error deleting room $roomId", e, s);
      rethrow;
    }
  }

  // Refresh method (if needed for explicit actions, though StreamBuilder handles most)
  Future<void> refreshRooms() async {
    _logger.info(
      "Explicit refresh requested by ViewModel for rooms in location: ${_currentLocation.name}",
    );
    // This method's utility depends on your DataService.
    // If your stream provider (e.g., Firestore) updates automatically, this might not be needed
    // for simple data refreshes.
    // If you have a DataService method to force a cache clear or re-fetch that also updates the stream:
    // Example: await _dataService.forceRefreshRoomsForLocation(_currentLocation.id);
    // For now, it's a placeholder as RoomsPage's _handleRefresh re-assigns the stream.
  }

  // --- Cleanup ---
  @override
  void dispose() {
    _logger.info(
      "RoomsViewModel disposing for location: ${_currentLocation.name} (ID: ${_currentLocation.id})",
    );
    super.dispose();
  }
}
