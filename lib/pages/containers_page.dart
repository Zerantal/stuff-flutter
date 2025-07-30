import 'package:flutter/material.dart';
import 'items_page.dart'; // To navigate to items
import '../models/room_data.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('ContainersPage');

class ContainersPage extends StatefulWidget {
  final RoomData roomData;

  const ContainersPage({super.key, required this.roomData});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> {
  late List<String> _containers;

  @override
  void initState() {
    super.initState();
    _containers = _fetchContainersForRoom(widget.roomData.roomId);
  }

  // Placeholder for data fetching logic
  List<String> _fetchContainersForRoom(String roomId) {
    _logger.info('Fetching containers for room ID: $roomId');
    return List.generate(4, (index) => 'Container ${index + 1}');
  }

  void _addNewContainer() {
    // TODO: Implement logic to add a new container
    // This would involve:
    // 1. Showing a dialog/form to get the new container's name.
    // 2. Updating your data source (e.g., API call, local database).
    // 3. Refreshing the UI (e.g., by calling setState if managing state locally
    //    or by relying on your state management solution to trigger a rebuild).
    setState(() {
      // Example: Simply add a new container to the local list for now
      final newContainerName = 'Container ${_containers.length + 1}';
      _containers.add(newContainerName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added $newContainerName to ${widget.roomData.roomName}',
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Containers in ${widget.roomData.roomName} (${widget.roomData.locationName})',
        ),
      ),
      body: ListView.builder(
        itemCount: _containers.length,
        itemBuilder: (context, index) {
          final containerName = _containers[index];
          return ListTile(
            title: Text(containerName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemsPage(
                    locationName: widget.roomData.locationName,
                    roomName: widget.roomData.roomName,
                    containerName: containerName,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewContainer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
