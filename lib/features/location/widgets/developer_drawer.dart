import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../services/contracts/data_service_interface.dart';
import '../../dev_tools/pages/database_inspector_page.dart';

final Logger _log = Logger('DeveloperDrawer');

class DeveloperDrawer extends StatefulWidget {
  const DeveloperDrawer({super.key, required this.onPopulateSampleData, this.onPopulated});

  /// Perform the actual sample data population (provided by the page).
  final Future<void> Function() onPopulateSampleData;

  /// Optional callback after population completes (page can wire vm.refresh()).
  final VoidCallback? onPopulated;

  @override
  State<DeveloperDrawer> createState() => _DeveloperDrawerState();
}

class _DeveloperDrawerState extends State<DeveloperDrawer> {
  bool _busy = false;

  Future<void> _handlePopulate() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await widget.onPopulateSampleData();
      messenger.showSnackBar(const SnackBar(content: Text('Sample data loaded')));
      _log.info('Sample data loaded');
      widget.onPopulated?.call();
    } catch (e, s) {
      messenger.showSnackBar(const SnackBar(content: Text('Sample data failed')));
      _log.severe('Failed to load sample data', e, s);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
              child: Text(
                'Developer Options',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_search),
              title: const Text('Database Inspector'),
              subtitle: const Text('Browse records (debug)'),
              onTap: () {
                final nav = Navigator.of(context); // capture before any await
                if (Navigator.canPop(context)) nav.pop(); // close drawer
                nav.push(
                  MaterialPageRoute<void>(
                    builder: (_) => Provider<IDataService>.value(
                      // Pass through the same IDataService already in scope
                      value: context.read<IDataService>(),
                      child: const DatabaseInspectorPage(),
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('dev_populate_btn'),
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Reset with Sample Data'),
              subtitle: const Text('Clears & seeds local DB for demo/testing'),
              enabled: !_busy,
              onTap: _handlePopulate,
              trailing: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
