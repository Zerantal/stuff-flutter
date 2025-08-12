// lib/pages/items_page.dart
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/item_page_arguments.dart'; // Import the arguments model
// import '../routing/app_routes.dart'; // For potential navigation from here (e.g., AddItem)

final Logger _logger = Logger('ItemsPage');

class ItemsPage extends StatefulWidget {
  // Changed to StatefulWidget for potential data fetching
  final ItemPageArguments args;

  const ItemsPage({super.key, required this.args});

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  // TODO: Replace List<String> with your actual ItemModel
  // late Future<List<ItemModel>> _itemsFuture;
  late List<String> _items; // Using placeholder

  @override
  void initState() {
    super.initState();
    _logger.info(
      "Initializing ItemsPage for Container: ${widget.args.containerName} (ID: ${widget.args.containerId ?? 'N/A'}) "
      "in Room: ${widget.args.roomName} (ID: ${widget.args.roomId}), "
      "Location: ${widget.args.locationName} (ID: ${widget.args.locationId})",
    );
    // TODO: Fetch actual items for the containerId
    // _itemsFuture = _fetchItemsForContainer(widget.args.containerId);
    _items = _fetchItemsForContainerPlaceholder(
      widget.args.containerId ?? widget.args.containerName,
    ); // Pass relevant ID
  }

  // Placeholder for data fetching logic
  List<String> _fetchItemsForContainerPlaceholder(String containerIdentifier) {
    _logger.info('Fetching items for container: $containerIdentifier (placeholder)');
    return List.generate(5, (index) => 'Item ${index + 1} in ${widget.args.containerName}');
  }

  // Future<List<ItemModel>> _fetchItemsForContainer(String containerId) async {
  //   // Call your data service here
  //   // return await myDataService.getItemsInContainer(containerId);
  // }

  // void _navigateToAddItem() {
  //   _logger.info("Navigating to add item for container: ${widget.args.containerName}");
  //   Navigator.of(context).pushNamed(
  //     AppRoutes.addItem, // You would define this route
  //     arguments: { // Pass all necessary IDs
  //       'containerId': widget.args.containerId, // Crucial
  //       'containerName': widget.args.containerName,
  //       'roomId': widget.args.roomId,
  //       'roomName': widget.args.roomName,
  //       'locationId': widget.args.locationId,
  //       'locationName': widget.args.locationName,
  //     },
  //   ).then((_) {
  //     _logger.info("Returned from AddItemPage. Consider refreshing item list.");
  //     // Refresh list if an item was added
  //   });
  // }

  void _navigateToViewItemDetails(String itemName /*, String itemId */) {
    _logger.info("Navigating to view/edit details for item: $itemName");
    // Example: Navigate to an "Edit Item" page
    // Navigator.of(context).pushNamed(
    //   AppRoutes.editItem,
    //   arguments: {
    //     'itemId': itemId,
    //     // ... other necessary data ...
    //   },
    // );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('View/Edit details for $itemName (TODO)')));
  }

  @override
  Widget build(BuildContext context) {
    // This page manages its own Scaffold and AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text('Items in ${widget.args.containerName}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            '${widget.args.roomName}, ${widget.args.locationName}',
            style: TextStyle(
              fontSize: 14,
              color: (Theme.of(context).appBarTheme.foregroundColor ?? Colors.white).withAlpha(
                (0.8 * 255).round(),
              ),
            ),
          ),
        ),
      ),
      // TODO: Replace with FutureBuilder/StreamBuilder using _itemsFuture
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final itemName = _items[index];
          // final item = _items[index]; // If using ItemModel
          // final itemName = item.name;
          // final itemId = item.id;

          return ListTile(
            title: Text(itemName),
            subtitle: Text('Details about $itemName...'),
            trailing: const Icon(Icons.edit_note_outlined), // Or view icon
            onTap: () {
              // TODO: Implement logic to view/edit item details, possibly navigating to a new page
              _navigateToViewItemDetails(itemName /*, itemId */);
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   heroTag: 'addItemFab',
      //   onPressed: _navigateToAddItem, // Updated to navigate
      //   tooltip: 'Add Item',
      //   child: const Icon(Icons.post_add_outlined),
      // ),
    );
  }
}
