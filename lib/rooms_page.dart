// lib/rooms_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'containers_page.dart';
import 'models/room_data.dart';

final Logger _logger = Logger('RoomsPage');

class RoomsPage extends StatefulWidget {
  final String locationName;
  final String locationId; // Add locationId
  final Function(String) updateAppBarTitle;

  const RoomsPage({
    super.key,
    required this.locationName,
    required this.locationId,
    required this.updateAppBarTitle,
  });

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.updateAppBarTitle('Rooms in ${widget.locationName}');
    });

    // Example: Initialize fetching of rooms for the given locationId
    // _roomsFuture = _fetchRoomsForLocation(widget.locationId);
    _logger.info(
      "Viewing rooms for Location ID: ${widget.locationId}, Name: ${widget.locationName}",
    );
  }

  @override
  Widget build(BuildContext context) {
    // This Widget will now be the BODY of MyHomePageWrapper's Scaffold
    return Stack(
      // Use Stack to position the FloatingActionButton
      children: [
        // Replace with your actual room fetching and display logic
        // For example, using a FutureBuilder if fetching data:
        /*
        FutureBuilder<List<Room>>(
          future: _roomsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading rooms: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No rooms found in this location.'));
            }

            final rooms = snapshot.data!;
            return ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return ListTile(
                  title: Text(room.name),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ContainersPage(
                          locationName: widget.locationName,
                          locationId: widget.locationId,
                          roomName: room.name, // Use actual room name
                          roomId: room.id,     // Use actual room ID
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        */

        // Using placeholder ListView.builder for now:
        ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 80,
          ), // Ensure FAB doesn't overlap last item
          itemCount: 5, // Replace with actual data fetching based on locationId
          itemBuilder: (context, index) {
            final roomName = 'Room ${index + 1}';
            // Example unique room ID incorporating location details
            final roomId =
                'room${index + 1}_${widget.locationId.substring(0, widget.locationId.length > 3 ? 3 : widget.locationId.length)}';
            return ListTile(
              title: Text(roomName),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContainersPage(
                      roomData: RoomData(
                        locationName: widget.locationName,
                        locationId: widget.locationId,
                        roomName: roomName,
                        roomId: roomId,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),

        Positioned(
          bottom: 16.0,
          right: 16.0,
          child: FloatingActionButton(
            onPressed: () {
              // TODO: Implement logic to add a new room to this location (using locationId)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Add new room to ${widget.locationName} (ID: ${widget.locationId}) tapped',
                  ),
                ),
              );
              // You might want to refresh the list of rooms here
            },
            tooltip: 'Add Room',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
