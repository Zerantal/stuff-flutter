import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/location_model.dart';
import '../../../domain/models/room_model.dart';
import '../../../services/contracts/data_service_interface.dart';

final _log = Logger('DatabaseInspectorPage');

class DatabaseInspectorPage extends StatefulWidget {
  const DatabaseInspectorPage({super.key});

  @override
  State<DatabaseInspectorPage> createState() => _DatabaseInspectorPageState();
}

class _DatabaseInspectorPageState extends State<DatabaseInspectorPage>
    with SingleTickerProviderStateMixin {
  int _tabIndex = 0;
  late final TabController _tab;
  List<DisplayableEntity> _activeTabDisplayableEntities = [];

  @override
  void initState() {
    super.initState();
    _log.finer('[DBInspector] initState: Creating TabController.');
    _tab = TabController(length: 2, vsync: this, initialIndex: _tabIndex);
    _tab.addListener(_onTabChanged);
    _log.finer('[DBInspector] initState: TabController created with index: ${_tab.index}');
  }

  void _onTabChanged() {
    _log.finer(
      '[DBInspector] _onTabChanged: Listener triggered. _tab.index: ${_tab.index}, _tab.indexIsChanging: ${_tab.indexIsChanging}, _tab.previousIndex: ${_tab.previousIndex}',
    );
    if (!_tab.indexIsChanging && mounted) {
      if (_tabIndex != _tab.index) {
        _log.finer(
          '[DBInspector] _onTabChanged: Updating _tabIndex from $_tabIndex to ${_tab.index}',
        );
        setState(() {
          _tabIndex = _tab.index;
          _activeTabDisplayableEntities = [];
        });
      }
    }
  }

  void _updateActiveTabEntities(List<DisplayableEntity> entities) {
    // Use addPostFrameCallback to ensure setState is not called during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _activeTabDisplayableEntities = entities;
        });
      }
    });
  }

  @override
  void dispose() {
    _log.finer('[DBInspector] dispose: Disposing TabController.');
    _tab.removeListener(_onTabChanged);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log.finer(
      '[DBInspector] build: Building widget. Current _tab.index: ${_tab.index}, _tabIndex: $_tabIndex',
    );
    return Scaffold(
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
            icon: const Icon(Icons.home_outlined), // Or Icons.apps, Icons.dashboard_outlined
            tooltip: 'Go to Main App',
            onPressed: () {
              StatefulNavigationShell.of(context).goBranch(0);
            },
          ),
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
          _LocationsTab(onEntitiesUpdated: _updateActiveTabEntities),
          _RoomsTab(onEntitiesUpdated: _updateActiveTabEntities),
        ],
      ),
    );
  }

  Future<void> _copyVisibleTab(BuildContext context) async {
    String dataToCopy;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_activeTabDisplayableEntities.isEmpty) {
      dataToCopy = "No entities to copy.";
    } else {
      dataToCopy = _activeTabDisplayableEntities
          .map((e) => e.rawTextForCopy)
          .join('\n-----------------------------\n');
    }

    await Clipboard.setData(ClipboardData(text: dataToCopy));

    if (!mounted) return;
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Copied tab content to clipboard! (${dataToCopy.length} chars)'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// --- Async Data Presenter ---------------------------------------------------

class AsyncDataPresenter<T> extends StatelessWidget {
  const AsyncDataPresenter({
    super.key,
    required this.snapshot,
    required this.dataBuilder,
    this.loadingWidget,
    this.errorBuilder,
  });

  final AsyncSnapshot<T> snapshot;
  final Widget Function(BuildContext context, T? data) dataBuilder;
  final Widget? loadingWidget;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (snapshot.hasError) {
      final error = snapshot.error;
      return errorBuilder?.call(context, error) ?? _ErrorPanel(error: error);
    }

    if (snapshot.hasData) {
      return dataBuilder(context, snapshot.data);
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    return dataBuilder(context, null); // For empty or default state when no data
  }
}

// --- Entity Display Abstraction ---------------------------------------------

abstract class DisplayableEntity {
  String get id;
  String get title;
  String get subtitle;
  List<Widget> getChildrenWidgets();
  String get rawTextForCopy;
}

class LocationAdapter implements DisplayableEntity {
  final Location _location;
  LocationAdapter(this._location);

  @override
  String get id => _location.id;

  @override
  String get title => _location.name;

  @override
  String get subtitle => [
    if ((_location.address ?? '').isNotEmpty) _location.address!,
    if ((_location.description ?? '').isNotEmpty) _location.description!,
  ].join(' • ');

  @override
  List<Widget> getChildrenWidgets() => [
    _KeyValue('id', _location.id),
    _KeyValue('name', _location.name),
    _KeyValue('address', _location.address),
    _KeyValue('description', _location.description),
    _KeyValue(
      'imageGuids',
      _location.imageGuids.isEmpty ? '(none)' : _location.imageGuids.join(', '),
    ),
  ];

  @override
  String get rawTextForCopy => _formatLocation(_location);
}

class RoomAdapter implements DisplayableEntity {
  final Room _room;
  RoomAdapter(this._room);

  @override
  String get id => _room.id;

  @override
  String get title => _room.name;

  @override
  String get subtitle => 'id: ${_room.id} • locationId: ${_room.locationId}';

  @override
  List<Widget> getChildrenWidgets() => [
    _KeyValue('id', _room.id),
    _KeyValue('name', _room.name),
    _KeyValue('locationId', _room.locationId),
    _KeyValue('description', _room.description),
    _KeyValue('images', _room.imageGuids.isEmpty ? '(none)' : _room.imageGuids.join(', ')),
  ];

  @override
  String get rawTextForCopy => _formatRoom(_room);
}

// --- Generic Entity List Display Widget -------------------------------------

class _EntityListDisplay extends StatelessWidget {
  const _EntityListDisplay({
    super.key, // ignore: unused_element_parameter
    required this.entities,
    required this.expandedSet,
    required this.onExpansionChanged,
    required this.noItemsText,
  });

  final List<DisplayableEntity> entities;
  final Set<String> expandedSet;
  final void Function(String itemId, bool isExpanded) onExpansionChanged;
  final String noItemsText;

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty) {
      return Center(child: Text(noItemsText));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: entities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entity = entities[index];
        return _ItemCard(
          itemId: entity.id,
          titleText: entity.title,
          subtitleText: entity.subtitle,
          rawTextToCopy: entity.rawTextForCopy,
          expandedInitially: expandedSet.contains(entity.id),
          onExpansionChanged: (isExpanded) => onExpansionChanged(entity.id, isExpanded),
          children: entity.getChildrenWidgets(),
        );
      },
    );
  }
}

class _LocationsTab extends StatefulWidget {
  final Function(List<DisplayableEntity>) onEntitiesUpdated;
  // ignore: unused_element_parameter
  const _LocationsTab({super.key, required this.onEntitiesUpdated});

  @override
  State<_LocationsTab> createState() => _LocationsTabState();
}

class _LocationsTabState extends State<_LocationsTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _search = TextEditingController();
  final Set<String> _expanded = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final data = context.read<IDataService>();
    final q = _search.text.trim().toLowerCase();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filter by name/address/description…',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Location>>(
            stream: data.getLocationsStream(),
            builder: (context, snap) {
              return AsyncDataPresenter<List<Location>>(
                snapshot: snap,
                dataBuilder: (context, locationsData) {
                  final list = (locationsData ?? const <Location>[]);
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

                  final displayableEntities = filtered.map((l) => LocationAdapter(l)).toList();

                  widget.onEntitiesUpdated(displayableEntities);

                  return _EntityListDisplay(
                    entities: displayableEntities,
                    expandedSet: _expanded,
                    onExpansionChanged: (itemId, isExpanded) {
                      setState(() {
                        if (isExpanded) {
                          _expanded.add(itemId);
                        } else {
                          _expanded.remove(itemId);
                        }
                      });
                    },
                    noItemsText: 'No locations match the filter.',
                  );
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
  final Function(List<DisplayableEntity>) onEntitiesUpdated;

  // ignore: unused_element_parameter
  const _RoomsTab({super.key, required this.onEntitiesUpdated});

  @override
  State<_RoomsTab> createState() => _RoomsTabState();
}

class _RoomsTabState extends State<_RoomsTab> with AutomaticKeepAliveClientMixin {
  final TextEditingController _locId = TextEditingController();
  String? _currentLocId;
  final Set<String> _expanded = <String>{};

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep-alive
    final data = context.read<IDataService>();

    Future<void> loadRooms() async {
      setState(() => _currentLocId = _locId.text.trim().isEmpty ? null : _locId.text.trim());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.tag),
                    labelText: 'Location ID',
                    hintText: 'Enter a locationId to load its rooms',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => loadRooms(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: loadRooms,
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
                    return AsyncDataPresenter<List<Room>>(
                      snapshot: snap,
                      dataBuilder: (context, roomsData) {
                        final rooms = roomsData ?? const <Room>[];
                        final displayableEntities = rooms.map((r) => RoomAdapter(r)).toList();

                        widget.onEntitiesUpdated(displayableEntities);

                        return _EntityListDisplay(
                          entities: displayableEntities,
                          expandedSet: _expanded,
                          onExpansionChanged: (itemId, isExpanded) {
                            setState(() {
                              if (isExpanded) {
                                _expanded.add(itemId);
                              } else {
                                _expanded.remove(itemId);
                              }
                            });
                          },
                          noItemsText: 'No rooms for this location.',
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locId.dispose();
    super.dispose();
  }
}

// --- Cards -------------------------------------------------------------------

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    super.key, // ignore: unused_element_parameter
    required this.itemId,
    required this.titleText,
    required this.subtitleText,
    required this.children,
    required this.rawTextToCopy,
    this.expandedInitially = false,
    this.onExpansionChanged,
  });

  final String itemId;
  final String titleText;
  final String subtitleText;
  final List<Widget> children;
  final String rawTextToCopy;
  final bool expandedInitially;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: PageStorageKey('item_$itemId'), // remember expanded state
        initiallyExpanded: expandedInitially,
        onExpansionChanged: onExpansionChanged,
        maintainState: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text(titleText, style: textTheme.titleMedium),
        subtitle: Text(subtitleText, maxLines: 2, overflow: TextOverflow.ellipsis),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          ...children,
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _copyText(context, itemId),
                icon: const Icon(Icons.copy),
                label: const Text('Copy ID'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _copyText(context, rawTextToCopy),
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
  const _KeyValue(this.k, this.v, {super.key}); // ignore: unused_element_parameter
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
  const _ErrorPanel({this.error, super.key}); // ignore: unused_element_parameter
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
