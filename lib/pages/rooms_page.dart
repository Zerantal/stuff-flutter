// lib/rooms_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/room_data.dart';
import '../models/location_model.dart';
import '../routing/app_routes.dart';

final Logger _logger = Logger('RoomsPage');

class RoomsPage extends StatefulWidget {
  final Location location;
  final Function(String) updateAppBarTitle;

  const RoomsPage({
    super.key,
    required this.location,
    required this.updateAppBarTitle,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  @override
  void initState() {
    super.initState();
    final locationName = widget.location.name;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.updateAppBarTitle(locationName);
    });

    _logger.info(
      "Viewing rooms for Location ID: ${widget.location.id}, Name: ${widget.location.name}",
    );

    // TODO: Initialize fetching of actual rooms for the given locationId
    // For example: _roomsFuture = _fetchRoomsForLocation(widget.location.id);
    // For now, we'll use placeholder data.
  }

  // Placeholder for fetching actual rooms - replace with your data service call
  // Future<List<ActualRoomModel>> _fetchRoomsForLocation(String locationId) async {
  //   _logger.info("Fetching rooms for location ID: $locationId");
  //   // Simulate network delay
  //   await Future.delayed(const Duration(seconds: 1));
  //   // Replace with actual data fetching logic
  //   // This is mock data
  //   return List.generate(5, (index) {
  //     return ActualRoomModel(
  //       id: 'room${index + 1}_${locationId.substring(0, 3)}',
  //       name: 'Actual Room ${index + 1}',
  //       locationId: locationId,
  //     );
  //   });
  // }

  // void _navigateToAddRoom() {
  //   _logger.info("Navigating to add new room for location: ${widget.location.name}");
  //   // Pass location details needed by the AddRoomPage
  //   Navigator.of(context).pushNamed(
  //     AppRoutes.addRoom,
  //     arguments: {
  //       'locationId': widget.location.id,
  //       'locationName': widget.location.name,
  //     },
  //   );
  //   // After AddRoomPage pops, you might need to refresh the list of rooms.
  //   // This can be handled by the stream/future builder if it re-fetches or listens to changes.
  // }

  @override
  Widget build(BuildContext context) {
    // This Widget will now be the BODY of MyHomePageWrapper's Scaffold.
    // It can still use a Stack internally to position its own FAB.

    // Using placeholder ListView.builder for now:
    // Replace this with a FutureBuilder or StreamBuilder once you have actual room fetching
    final itemCount = 5; // Placeholder count

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 80, // Ensure FAB doesn't overlap last item
            top: 8,
            left: 8,
            right: 8, // Added some padding around the list
          ),
          itemCount:
              itemCount, // Replace with actual_rooms.length when using FutureBuilder
          itemBuilder: (context, index) {
            // Placeholder room data - replace with data from your _roomsFuture/Stream
            final roomName = 'Room ${index + 1} at ${widget.location.name}';
            final roomId =
                'room${index + 1}_${widget.location.id.length > 3 ? widget.location.id.substring(0, 3) : widget.location.id}';

            // final actualRoom = actual_rooms[index]; // Use this with FutureBuilder data
            // final roomName = actualRoom.name;
            // final roomId = actualRoom.id;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ListTile(
                title: Text(roomName),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _logger.info("Tapped on room: $roomName (ID: $roomId)");
                  final roomData = RoomData(
                    locationName: widget.location.name,
                    locationId: widget.location.id,
                    roomName: roomName, // Use actualRoom.name
                    roomId: roomId, // Use actualRoom.id
                  );
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.containers, arguments: roomData);
                },
              ),
            );
          },
        ),
        // Positioned(
        //   bottom: 16.0,
        //   right: 16.0,
        //   child: FloatingActionButton(
        //     heroTag: 'addRoomFab', // Ensure unique heroTag if multiple FABs might be on screen transition
        //     onPressed: _navigateToAddRoom,
        //     tooltip: 'Add Room to ${widget.location.name}',
        //     child: const Icon(Icons.add_circle_outline), // Changed icon slightly
        //   ),
        // ),
      ],
    );

    // Example with FutureBuilder (once you have _fetchRoomsForLocation and ActualRoomModel)
    /*
    return FutureBuilder<List<ActualRoomModel>>(
      future: _roomsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          _logger.severe("Error loading rooms: ${snapshot.error}", snapshot.error, snapshot.stackTrace);
          return Center(child: Text('Error loading rooms: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          _logger.info("No rooms found for location ID: ${widget.location.id}");
          // Show an empty state with an "Add Room" button
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No rooms found in ${widget.location.name}.'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Add First Room'),
                  onPressed: _navigateToAddRoom,
                ),
              ],
            ),
          );
        }

        final rooms = snapshot.data!;
        _logger.fine("Successfully loaded ${rooms.length} rooms for location: ${widget.location.name}");

        return Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 80, top: 8, left: 8, right: 8),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ListTile(
                    title: Text(room.name),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _logger.info("Tapped on room: ${room.name} (ID: ${room.id})");
                      final roomData = RoomData(
                        locationName: widget.location.name,
                        locationId: widget.location.id,
                        roomName: room.name,
                        roomId: room.id,
                      );
                       Navigator.of(context).pushNamed(
                         AppRoutes.containers,
                         arguments: roomData,
                       );
                    },
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16.0,
              right: 16.0,
              child: FloatingActionButton(
                heroTag: 'addRoomFabInFuture',
                onPressed: _navigateToAddRoom,
                tooltip: 'Add Room to ${widget.location.name}',
                child: const Icon(Icons.add_circle_outline),
              ),
            ),
          ],
        );
      },
    );
    */
  }
}

// Define your actual Room model if you don't have one already
// class ActualRoomModel {
//   final String id;
//   final String name;
//   final String locationId;
//   // Add other properties like description, imageGuids, etc.

//   ActualRoomModel({
//     required this.id,
//     required this.name,
//     required this.locationId,
//   });
// }
