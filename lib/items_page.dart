import 'package:flutter/material.dart';

class ItemsPage extends StatelessWidget {
  final String locationName;
  final String roomName;
  final String containerName;

  const ItemsPage({
    super.key,
    required this.locationName,
    required this.roomName,
    required this.containerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Items in $containerName'),
        bottom: PreferredSize( // Optional: Subtitle for more context
          preferredSize: const Size.fromHeight(20.0),
          child: Text(
            '$roomName, $locationName',
            style: TextStyle(color: Theme
                .of(context)
                .appBarTheme
                .foregroundColor
                 ?? Colors.white70),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: 10, // Example: 10 items per container
        itemBuilder: (context, index) {
          final itemName = 'Item ${index + 1}'; // Example data
          return ListTile(
            title: Text(itemName),
            subtitle: Text('Details about $itemName...'),
            // Add more item details
            onTap: () {
              // TODO: Implement logic to view/edit item details
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('View details for $itemName')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement logic to add a new item to this container
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Add new item to $containerName tapped')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}