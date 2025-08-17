import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/location_model.dart';
import '../../../domain/models/room_model.dart';
import '../../../services/contracts/data_service_interface.dart';

class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _roomsForLocationCtrl = TextEditingController();
  TabController? _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _roomsForLocationCtrl.dispose();
    _tab?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {},
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Database Inspector'),
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Locations', icon: Icon(Icons.place_outlined)),
              Tab(text: 'Rooms', icon: Icon(Icons.meeting_room_outlined)),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Copy current tab as text',
              icon: const Icon(Icons.copy_all_outlined),
              onPressed: () => _copyVisibleTab(context),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _LocationsTab(searchCtrl: _searchCtrl),
            _RoomsTab(locationIdCtrl: _roomsForLocationCtrl),
          ],
        ),
      ),
    );
  }

  Future<void> _copyVisibleTab(BuildContext context) async {
    final data = switch (_tab?.index ?? 0) {
      0 => 'Locations tab selection',
      1 => 'Rooms tab selection',
      _ => '',
    };
    final scaffoldMessenger = ScaffoldMessenger.of(context); // capture
    await Clipboard.setData(ClipboardData(text: data));

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Copied!')));
  }
}

class _LocationsTab extends StatelessWidget {
  const _LocationsTab({required this.searchCtrl});
  final TextEditingController searchCtrl;

  @override
  Widget build(BuildContext context) {
    final data = context.read<IDataService>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchCtrl,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter by name/address/description…',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => (context as Element).markNeedsBuild(),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Location>>(
            stream: data.getLocationsStream(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorPanel(error: snap.error);
              }
              final list = (snap.data ?? const <Location>[]);

              final q = searchCtrl.text.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? list
                  : list.where((l) {
                      final name = l.name.toLowerCase();
                      final desc = (l.description ?? '').toLowerCase();
                      final addr = (l.address ?? '').toLowerCase();
                      return name.contains(q) ||
                          desc.contains(q) ||
                          addr.contains(q) ||
                          l.id.contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No locations match the filter.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final l = filtered[i];
                  return _LocationCard(loc: l);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomsTab extends StatefulWidget {
  const _RoomsTab({required this.locationIdCtrl});
  final TextEditingController locationIdCtrl;

  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> {
  String? _currentLocId; // null => nothing loaded

  @override
  Widget build(BuildContext context) {
    final data = context.read<IDataService>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.locationIdCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tag),
                    labelText: 'Location ID',
                    hintText: 'Enter a locationId to load its rooms',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) =>
                      setState(() => _currentLocId = widget.locationIdCtrl.text.trim()),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => setState(() => _currentLocId = widget.locationIdCtrl.text.trim()),
                icon: const Icon(Icons.search),
                label: const Text('Load'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _currentLocId == null || _currentLocId!.isEmpty
              ? const Center(child: Text('Enter a Location ID and tap Load.'))
              : FutureBuilder<List<Room>>(
                  future: data.getRoomsForLocation(_currentLocId!),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return _ErrorPanel(error: snap.error);
                    }
                    final rooms = snap.data ?? const <Room>[];
                    if (rooms.isEmpty) {
                      return const Center(child: Text('No rooms for this location.'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: rooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _RoomCard(room: rooms[i]),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// --- Cards -------------------------------------------------------------------

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.loc});
  final Location loc;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(loc.name, style: textTheme.titleMedium),
        subtitle: Text(
          [
            if ((loc.address ?? '').isNotEmpty) loc.address!,
            if ((loc.description ?? '').isNotEmpty) loc.description!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _KeyValue('id', loc.id),
          _KeyValue('name', loc.name),
          _KeyValue('address', loc.address),
          _KeyValue('description', loc.description),
          _KeyValue('imageGuids', loc.imageGuids.isEmpty ? '(none)' : loc.imageGuids.join(', ')),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _copyText(context, loc.id),
                icon: const Icon(Icons.copy),
                label: const Text('Copy ID'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _copyText(context, _formatLocation(loc)),
                icon: const Icon(Icons.code),
                label: const Text('Copy as text'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room});
  final Room room;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(room.name, style: textTheme.titleMedium),
        subtitle: Text('id: ${room.id} • locationId: ${room.locationId}'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          _KeyValue('id', room.id),
          _KeyValue('name', room.name),
          _KeyValue('locationId', room.locationId),
          _KeyValue('description', room.description),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _copyText(context, room.id),
                icon: const Icon(Icons.copy),
                label: const Text('Copy ID'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _copyText(context, _formatRoom(room)),
                icon: const Icon(Icons.code),
                label: const Text('Copy as text'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Small helpers -----------------------------------------------------------

class _KeyValue extends StatelessWidget {
  const _KeyValue(this.k, this.v);
  final String k;
  final String? v;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final val = (v == null || v!.isEmpty) ? '—' : v!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: theme.bodySmall)),
          Expanded(child: Text(val, style: theme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({this.error});
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: ${error ?? 'unknown'}',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

String _formatLocation(Location l) =>
    '''
Location(
  id: ${l.id},
  name: ${l.name},
  address: ${l.address ?? '(null)'},
  description: ${l.description ?? '(null)'},
  images: [${l.imageGuids.join(', ')}],
)''';

String _formatRoom(Room r) =>
    '''
Room(
  id: ${r.id},
  name: ${r.name},
  locationId: ${r.locationId},
  description: ${r.description ?? '(null)'},
)''';

Future<void> _copyText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
}
