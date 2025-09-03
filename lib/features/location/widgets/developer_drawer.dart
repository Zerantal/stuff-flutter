// lib/features/location/widgets/developer_drawer.dart
// coverage:ignore-file

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';

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
  bool _busyPopulating = false;
  bool _busyDumping = false;

  Future<void> _handlePopulate() async {
    if (_busyPopulating) return;
    setState(() => _busyPopulating = true);
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
      if (mounted) setState(() => _busyPopulating = false);
    }
  }

  Future<void> _handleDumpWidgetTree() async {
    if (_busyDumping) return;
    setState(() => _busyDumping = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final String? treeDump = WidgetsBinding.instance.rootElement
          ?.toDiagnosticsNode()
          .toStringDeep(minLevel: DiagnosticLevel.fine);
      if (treeDump == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Widget tree is empty')));
        _log.warning('Widget tree dump was empty');
        return;
      }
      final file = File('${Directory.systemTemp.path}/widget_tree_dump.txt');
      await file.writeAsString(treeDump);
      messenger.showSnackBar(SnackBar(content: Text('Widget tree dumped to ${file.path}')));
      _log.info('Widget tree dumped to ${file.path}');
    } catch (e, s) {
      messenger.showSnackBar(const SnackBar(content: Text('Failed to dump widget tree')));
      _log.severe('Failed to dump widget tree', e, s);
    } finally {
      if (mounted) setState(() => _busyDumping = false);
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
                StatefulNavigationShell.of(context).goBranch(1);

                Navigator.pop(context);
                AppRoutes.debugDbInspector.go(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('dev_populate_btn'),
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Reset with Sample Data'),
              subtitle: const Text('Clears & seeds local DB for demo/testing'),
              enabled: !_busyPopulating,
              onTap: _handlePopulate,
              trailing: _busyPopulating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
            const Divider(height: 1),
            ListTile(
              key: const ValueKey('dev_dump_widget_tree_btn'),
              leading: const Icon(Icons.description_outlined),
              title: const Text('Dump Widget Tree'),
              subtitle: const Text('Saves current widget tree to a file'),
              enabled: !_busyDumping,
              onTap: _handleDumpWidgetTree,
              trailing: _busyDumping
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
