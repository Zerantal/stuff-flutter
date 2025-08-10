// lib/pages/rooms_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stuff/services/image_data_service_legacy_shim.dart';
// Models and Services
import '../models/location_model.dart';
import '../models/room_model.dart';
import '../services/image_data_service_interface.dart';
import '../services/data_service_interface.dart';
// ViewModel
import '../viewmodels/rooms_view_model.dart';

final Logger _logger = Logger('RoomsPage');

class RoomsPage extends StatefulWidget {
  final Location location;

  const RoomsPage({super.key, required this.location});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  late IDataService _dataService;
  Stream<List<Room>>? _roomsStream;
  late RoomsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _dataService = Provider.of<IDataService>(context, listen: false);
    _roomsStream = _dataService.getRoomsStream(widget.location.id);
    _logger.info(
      "RoomsPage: Subscribed to rooms stream for location ID: ${widget.location.id}",
    );

    _viewModel = RoomsViewModel(
      dataService: _dataService,
      location: widget.location,
    );
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    Room room,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Room'),
          content: Text(
            'Are you sure you want to delete "${room.name}" and all its contents? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              child: const Text('Delete Room'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _handleRefresh() async {
    _logger.info(
      "Handling refresh via RefreshIndicator for rooms in ${widget.location.name}...",
    );
    if (mounted) {
      setState(() {
        // Re-assigning the stream can force StreamBuilder to re-listen
        _roomsStream = _dataService.getRoomsStream(widget.location.id);
      });
      // Optionally, if your data service has an explicit fetch that also updates the stream:
      // await _dataService.fetchRoomsForLocation(widget.location.id, forceRefresh: true); // Example
    }
    _logger.info("RefreshIndicator for rooms completed.");
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("RoomsPage building with location: ${widget.location.name}");

    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          // Set the title directly here
          title: Text('Rooms in "${widget.location.name}"'),
        ),
        body: RefreshIndicator(
          key: const Key("rooms_refresh_indicator"),
          onRefresh: _handleRefresh,
          child: Consumer<IImageDataService?>(
            builder: (context, imageDataService, _) {
              _logger.finer(
                "RoomsPage Consumer<IImageDataService>: Service is ${imageDataService == null ? 'NULL' : 'AVAILABLE'}",
              );
              return StreamBuilder<List<Room>>(
                stream: _roomsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !(snapshot.hasData || snapshot.hasError)) {
                    _logger.finer(
                      "StreamBuilder (Rooms): ConnectionState.waiting (initial load likely)",
                    );
                    return _buildLoadingIndicator();
                  }
                  if (snapshot.hasError) {
                    _logger.warning(
                      "StreamBuilder (Rooms): Error: ${snapshot.error}",
                      snapshot.error,
                      snapshot.stackTrace,
                    );
                    return _buildErrorState(
                      context,
                      snapshot.error.toString(),
                      () {
                        if (mounted) {
                          setState(() {
                            // Retry by re-assigning the stream
                            _roomsStream = _dataService.getRoomsStream(
                              widget.location.id,
                            );
                          });
                        }
                      },
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.data == null ||
                      snapshot.data!.isEmpty) {
                    _logger.info(
                      "StreamBuilder (Rooms): No data or empty list for location ${widget.location.name}.",
                    );
                    // Access viewModel directly from _RoomsPageState as it's available
                    return _buildEmptyState(context, _viewModel);
                  }

                  final rooms = snapshot.data!;
                  _logger.fine(
                    "StreamBuilder (Rooms): HasData with ${rooms.length} items for ${widget.location.name}.",
                  );
                  // Access viewModel directly
                  return _buildRoomsList(
                    context,
                    _viewModel,
                    rooms,
                    imageDataService,
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          key: const Key('add_room_fab'),
          onPressed: () => _viewModel.navigateToAddRoom(context),
          tooltip: 'Add New Room',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    _logger.finer("RoomsPage: Building Loading Indicator");
    return const Center(
      child: CircularProgressIndicator(key: Key("rooms_waiting_spinner")),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    String errorMessage,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Error loading rooms:',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, RoomsViewModel viewModel) {
    _logger.info(
      "RoomsPage: Building Empty State for location ${viewModel.currentLocation.name}",
    );
    return LayoutBuilder(
      builder: (lbContext, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.meeting_room_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rooms found in "${viewModel.currentLocation.name}" yet.',
                      textAlign: TextAlign.center,
                      style: Theme.of(lbContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button below to add the first room.',
                      textAlign: TextAlign.center,
                      style: Theme.of(lbContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomImage(Room room, IImageDataService? imageDataService) {
    _logger.fine(
      "Building image for room ${room.id}. ImageDataService is ${imageDataService == null ? 'NULL' : 'AVAILABLE'}. Image GUIDs: ${room.imageGuids}",
    );

    if (imageDataService != null &&
        room.imageGuids != null &&
        room.imageGuids!.isNotEmpty) {
      final firstImageGuid = room.imageGuids!.firstWhere(
        (guid) => guid.isNotEmpty,
        orElse: () => '',
      );

      if (firstImageGuid.isNotEmpty) {
        return imageDataService.getUserImage(
          firstImageGuid,
          width: 60.0,
          height: 60.0,
          fit: BoxFit.cover,
        );
      }
    }
    return Image.asset(
      'assets/images/room_placeholder.jpg',
      height: 60.0,
      width: 60.0,
      fit: BoxFit.cover,
      key: Key('placeholder_room_image_${room.id}_fallback'),
    );
  }

  Widget _buildRoomCard(
    BuildContext context,
    RoomsViewModel viewModel, // Passed from _buildRoomsList
    Room room,
    IImageDataService? imageDataService,
  ) {
    _logger.finer("Building card for room ${room.name}");
    return Card(
      key: ValueKey('room_card_${room.id}'), // Good for list updates
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: InkWell(
        onTap: () => viewModel.navigateToViewRoomContents(context, room),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildRoomImage(room, imageDataService),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (room.description != null &&
                        room.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          room.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                key: Key('room_options_${room.id}'),
                onSelected: (value) async {
                  if (value == 'edit') {
                    if (!mounted) return;
                    viewModel.navigateToEditRoom(context, room);
                  } else if (value == 'delete') {
                    if (!mounted) return;
                    final scaffoldMessenger = ScaffoldMessenger.of(
                      context,
                    ); // capture

                    final confirmed = await _showDeleteConfirmationDialog(
                      context,
                      room,
                    );
                    if (confirmed && mounted) {
                      bool roomDeletedSuccessfully = false;
                      String? errorMessage;

                      try {
                        await viewModel.deleteRoom(room.id, room.name);
                        roomDeletedSuccessfully = true;
                      } catch (e) {
                        _logger.severe(
                          "Error deleting room from card action: ${room.id}",
                          e,
                        );
                        errorMessage = e.toString();
                      }

                      // Check mounted again after delete operation
                      if (mounted) {
                        if (roomDeletedSuccessfully) {
                          scaffoldMessenger.showSnackBar(
                            // Use captured scaffoldMessenger
                            SnackBar(
                              content: Text('Room "${room.name}" deleted.'),
                            ),
                          );
                        } else if (errorMessage != null) {
                          scaffoldMessenger.showSnackBar(
                            // Use captured scaffoldMessenger
                            SnackBar(
                              content: Text(
                                'Failed to delete room: $errorMessage',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (BuildContext popupContext) =>
                    <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Room'),
                        ),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          title: Text(
                            'Delete Room',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                icon: const Icon(Icons.more_vert),
                tooltip: "Room options",
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsList(
    BuildContext context,
    RoomsViewModel viewModel, // Passed from build method
    List<Room> rooms,
    IImageDataService? imageDataService,
  ) {
    _logger.fine("RoomsPage: Building Rooms List with ${rooms.length} rooms.");
    // The empty state is already handled by the StreamBuilder's conditions.
    // So, no explicit check for rooms.isEmpty here is strictly necessary.
    return ListView.builder(
      key: const Key('rooms_list_view'),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _buildRoomCard(context, viewModel, room, imageDataService);
      },
    );
  }
}
