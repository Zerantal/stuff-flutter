// lib/features/location/widgets/developer_drawer.dart
// coverage:ignore-file

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../app/routing/app_routes.dart';
import '../../../app/routing/app_routes_ext.dart';
import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/sample_data_populator.dart';

final Logger _log = Logger('DeveloperDrawer');

class DeveloperDrawer extends StatefulWidget {
  const DeveloperDrawer({super.key});

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
      final data = context.read<IDataService>();
      IImageDataService? images;
      try {
        images = context.read<IImageDataService>();
      } catch (_) {
        images = null; // allowed: seeding works without images
      }

      final populator = SampleDataPopulator(
        dataService: data,
        imageDataService: images,
        // default SampleOptions() – clears DB, includes base seeds, some extras
      );
      await populator.populate();

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Sample data loaded')));
      _log.info('Sample data loaded');
    } catch (e, s) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Sample data failed')));
      _log.severe('Failed to load sample data', e, s);
    } finally {
      if (mounted) setState(() => _busyPopulating = false);
    }
  }

  Future<void> _handlePopulateRandom() async {
    if (_busyPopulating) return;
    StatefulNavigationShell.of(context).goBranch(1);
    context.pop();
    AppRoutes.debugSampleDbRandomiser.go(context);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Random data loaded')));
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
                context.pop();
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
              key: const ValueKey('dev_populate_random_btn'),
              leading: const Icon(Icons.auto_fix_high_outlined),
              title: const Text('Reset with Random Data…'),
              subtitle: const Text('Choose counts/seed, then populate'),
              onTap: _handlePopulateRandom,
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
