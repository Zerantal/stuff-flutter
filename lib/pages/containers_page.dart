import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../app/routing/app_route_ext.dart';
import '../app/routing/app_routes.dart';
import '../models/room_model.dart';

final Logger _logger = Logger('ContainersPage');

class ContainersPage extends StatefulWidget {
  final Room room;

  const ContainersPage({super.key, required this.room});

  @override
  State<ContainersPage> createState() => _ContainersPageState();
}

class _ContainersPageState extends State<ContainersPage> {
  // TODO: Replace List<String> with your actual ContainerModel
  // late Future<List<ContainerModel>> _containersFuture;
  late List<String> _containers;

  @override
  void initState() {
    super.initState();
    _logger.info(
      "Initializing ContainersPage for Room: ${widget.room.name} (ID: ${widget.room.id})",
    );
    // TODO: Fetch actual containers from a data service
    // _containersFuture = _fetchContainersForRoom(widget.roomData.roomId);
    _containers = _fetchContainersForRoomPlaceholder(widget.room.id);
  }

  // Placeholder for data fetching logic - replace with actual data service
  List<String> _fetchContainersForRoomPlaceholder(String roomId) {
    _logger.info('Fetching containers for room ID: $roomId (placeholder)');
    // In a real app, this would return List<ContainerModel> from a service
    return List.generate(4, (index) => 'Container ${index + 1} in ${widget.room.name}');
  }

  // Future<List<ContainerModel>> _fetchContainersForRoom(String roomId) async {
  //   // Call your data service here
  //   // return await myDataService.getContainersInRoom(roomId);
  // }

  void _navigateToAddContainer() {
    _logger.info("Navigating to add container for room: ${widget.room.name}");

    AppRoutes.containersAdd.go(context, pathParams: {'roomId': widget.room.id});
  }

  // void _addNewContainer() {
  //   // TODO: Implement logic to add a new container
  //   // This would involve:
  //   // 1. Showing a dialog/form to get the new container's name.
  //   // 2. Updating your data source (e.g., API call, local database).
  //   // 3. Refreshing the UI (e.g., by calling setState if managing state locally
  //   //    or by relying on your state management solution to trigger a rebuild).
  //   setState(() {
  //     // Example: Simply add a new container to the local list for now
  //     final newContainerName = 'Container ${_containers.length + 1}';
  //     _containers.add(newContainerName);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           'Added $newContainerName to ${widget.roomData.roomName}',
  //         ),
  //       ),
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // This page manages its own Scaffold and AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text('Containers in ${widget.room.name}'),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(20.0),
        // child: Text(
        //   widget.roomData.locationName, // Display location context
        //   style: TextStyle(
        //     fontSize: 14,
        //     color:
        //         (Theme.of(context).appBarTheme.foregroundColor ??
        //                 Colors.white)
        //             .withAlpha((0.8 * 255).round()),
        //   ),
        // ),
        // ),
      ),
      // TODO: Replace with FutureBuilder/StreamBuilder using _containersFuture
      body: ListView.builder(
        itemCount: _containers.length,
        itemBuilder: (context, index) {
          final containerName = _containers[index];
          // final container = _containers[index]; // If using ContainerModel
          // final containerName = container.name;
          // final containerId = container.id;

          return ListTile(
            title: Text(containerName),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _logger.info("Tapped on container: $containerName");
              // final args = null;
              // final args = ItemPageArguments(
              //   locationName: widget.roomData.locationName,
              //   locationId: widget.roomData.locationId,
              //   roomName: widget.roomData.roomName,
              //   roomId: widget.roomData.roomId,
              //   containerName: containerName, // Use actual container.name
              //   // containerId: containerId,    // Use actual container.id
              // );
              AppRoutes.items.go(context);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addContainerFab',
        onPressed: _navigateToAddContainer, // Updated to navigate
        tooltip: 'Add Container',
        child: const Icon(Icons.add_box_outlined),
      ),
    );
  }
}
