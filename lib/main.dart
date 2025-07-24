// main.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'locations_page.dart';
import 'rooms_page.dart';
import 'models/location_model.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) {
      // Standard print for console output during development
      print(
        '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
      );
      if (record.error != null) {
        print('Error: ${record.error}, StackTrace: ${record.stackTrace}');
      }
    } else {
      if (record.level >= Level.SEVERE) {
        // Send to crash reporting service (e.g., Sentry, Firebase Crashlytics)
      }
    }
  });

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  await DatabaseService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stuff',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),
      home: const MyHomePageWrapper(),
    );
  }
}

enum ActiveView { locations, rooms }

class MyHomePageWrapper extends StatefulWidget {
  const MyHomePageWrapper({super.key});

  @override
  State<MyHomePageWrapper> createState() => _MyHomePageWrapperState();
}

class _MyHomePageWrapperState extends State<MyHomePageWrapper> {
  String _appBarTitle = 'Locations'; // Default title
  ActiveView _currentView = ActiveView.locations;

  // Parameters for RoomsPage if _currentView is rooms
  String? _selectedLocationId;
  String? _selectedLocationName;

  Future<void> _resetDatabaseWithSampleData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
            'Are you sure you want to reset ALL inventory data to the sample set? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Reset All Data'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resetting database... Please wait.')),
      );
      await DatabaseService.populateSampleData();
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database has been reset with sample data.'),
          ),
        );
      }
    }
  }

  // Callback to update the AppBar title from child pages
  void _updateAppBarTitle(String newTitle) {
    if (mounted) {
      setState(() {
        _appBarTitle = newTitle;
      });
    }
  }

  // Method to navigate to the Rooms view
  void _navigateToRooms(Location location) {
    setState(() {
      _currentView = ActiveView.rooms;
      _selectedLocationId = location.id;
      _selectedLocationName = location.name;
    });
  }

  // Method to go back to Locations view from Rooms view
  void _navigateBackToLocations() {
    setState(() {
      _currentView = ActiveView.locations;
      _selectedLocationId = null;
      _selectedLocationName = null;
      _appBarTitle = 'Locations'; // Reset title
    });
  }

  Widget _buildBody() {
    switch (_currentView) {
      case ActiveView.locations:
        return LocationsPage(
          onViewLocationContents: _navigateToRooms,
          // If LocationsPage ever needs to dynamically set the title (e.g. "Locations (3)")
          // you could pass it like this:
          // updateAppBarTitle: _updateAppBarTitle,
        );
      case ActiveView.rooms:
        if (_selectedLocationId != null && _selectedLocationName != null) {
          return RoomsPage(
            locationId: _selectedLocationId!,
            locationName: _selectedLocationName!,
            updateAppBarTitle: _updateAppBarTitle,
          );
        }
        // Fallback or error state if parameters are missing
        // This should ideally not be reached if navigation is managed correctly
        return const Center(
          child: Text('Error: Location data missing for rooms view.'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canGoBackToLocations = _currentView == ActiveView.rooms;

    return Scaffold(
      appBar: AppBar(
        // This is the MAIN AppBar
        title: Text(_appBarTitle),
        leading: canGoBackToLocations
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _navigateBackToLocations,
                tooltip: 'Back to Locations',
              )
            : (kDebugMode // Only show drawer button if not showing back button AND in debug mode
                  ? Builder(
                      // Use Builder to get context for Scaffold.of
                      builder: (BuildContext appBarContext) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          tooltip: 'Developer Options',
                          onPressed: () {
                            // Use appBarContext which is under the Scaffold
                            Scaffold.of(appBarContext).openDrawer();
                          },
                        );
                      },
                    )
                  : null),
      ),
      drawer: kDebugMode
          ? Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.teal),
                    child: Text(
                      'Developer Options',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.dataset_outlined),
                    title: const Text('Reset DB with Sample Data'),
                    onTap: () async {
                      Navigator.pop(context); // Close the drawer first
                      await _resetDatabaseWithSampleData(); // Call the stateful method
                    },
                  ),
                  // Add other developer options here
                ],
              ),
            )
          : null,
      body: _buildBody(),
    );
  }
}
