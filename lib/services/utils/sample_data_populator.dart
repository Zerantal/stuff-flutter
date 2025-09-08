// services/util/sample_data_populator.dart
// coverage:ignore-file

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/location_model.dart';
import '../../domain/models/room_model.dart';
import '../../domain/models/container_model.dart';
import '../../domain/models/item_model.dart';

import '../contracts/data_service_interface.dart';
import '../contracts/image_data_service_interface.dart';

final Logger _logger = Logger('SampleDataPopulator');
const Uuid _uuid = Uuid();

/// Knobs for counts and randomization. Defaults keep prior behavior.
class SampleOptions {
  /// If true, wipes all tables before seeding.
  final bool clearExistingData;

  /// If true and image service is available, clears all persisted images.
  final bool clearImages;

  /// Seed for deterministic randomness (null -> time-based).
  final int? randomSeed;

  /// Whether to include the base “hand-authored” seeds (locations, rooms, a few containers/items).
  final bool includeBaseSeeds;

  /// Extra top-level containers per room (in addition to base seeds).
  final int extraTopLevelContainersPerRoom;

  /// Extra *child* containers to create under **each** top-level container (base + extra).
  final int extraChildContainersPerTopLevel;

  /// Extra room-level items per room (containerId == null).
  final int extraItemsPerRoom;

  /// Extra items per container (for each container created).
  final int extraItemsPerContainer;

  /// Probabilities to attach a random image when an image pool exists.
  final double containerImageChance; // 0..1
  final double itemImageChance; // 0..1

  const SampleOptions({
    this.clearExistingData = true,
    this.clearImages = true,
    this.randomSeed,
    this.includeBaseSeeds = true,
    this.extraTopLevelContainersPerRoom = 1,
    this.extraChildContainersPerTopLevel = 1,
    this.extraItemsPerRoom = 2,
    this.extraItemsPerContainer = 2,
    this.containerImageChance = 0.85,
    this.itemImageChance = 0.65,
  });

  SampleOptions copyWith({
    bool? clearExistingData,
    bool? clearImages,
    int? randomSeed,
    bool? includeBaseSeeds,
    int? extraTopLevelContainersPerRoom,
    int? extraChildContainersPerTopLevel,
    int? extraItemsPerRoom,
    int? extraItemsPerContainer,
    double? containerImageChance,
    double? itemImageChance,
  }) {
    return SampleOptions(
      clearExistingData: clearExistingData ?? this.clearExistingData,
      clearImages: clearImages ?? this.clearImages,
      randomSeed: randomSeed ?? this.randomSeed,
      includeBaseSeeds: includeBaseSeeds ?? this.includeBaseSeeds,
      extraTopLevelContainersPerRoom:
          extraTopLevelContainersPerRoom ?? this.extraTopLevelContainersPerRoom,
      extraChildContainersPerTopLevel:
          extraChildContainersPerTopLevel ?? this.extraChildContainersPerTopLevel,
      extraItemsPerRoom: extraItemsPerRoom ?? this.extraItemsPerRoom,
      extraItemsPerContainer: extraItemsPerContainer ?? this.extraItemsPerContainer,
      containerImageChance: containerImageChance ?? this.containerImageChance,
      itemImageChance: itemImageChance ?? this.itemImageChance,
    );
  }
}

// -----------------------------------------------------------------------------
// Seed structs
// -----------------------------------------------------------------------------

class _LocationSeed {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? imageKey; // key into image pools
  const _LocationSeed({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.imageKey,
  });
}

class _RoomSeed {
  final String locationId;
  final String name;
  final String? description;
  final String? imageKey;
  const _RoomSeed({required this.locationId, required this.name, this.description, this.imageKey});
}

class _ContainerSeed {
  final String key; // local key to wire parent relationships
  final String? parentKey;
  final String nameTemplate; // may include "{room}"
  final String? descriptionTemplate;
  final String? imageKey;
  const _ContainerSeed({
    required this.key,
    this.parentKey,
    required this.nameTemplate,
    this.descriptionTemplate,
    this.imageKey,
  });
}

class _ItemSeed {
  final String nameTemplate; // may include "{room}"
  final String? descriptionTemplate;
  final String? imageKey;
  final String? containerKey; // null -> room-level item
  const _ItemSeed({
    required this.nameTemplate,
    this.descriptionTemplate,
    this.imageKey,
    this.containerKey,
  });
}

// -----------------------------------------------------------------------------
// Default seeds (edit freely)
// -----------------------------------------------------------------------------

const List<_LocationSeed> _kLocationSeeds = [
  _LocationSeed(
    id: 'loc_sample_home',
    name: 'Cozy Home',
    description: 'Primary residence with a small garden.',
    address: '123 Sample St, Testville',
    imageKey: 'home',
  ),
  _LocationSeed(
    id: 'loc_sample_office',
    name: 'Downtown Office',
    description: 'Vacuum cleaner business.',
    address: '456 Dev Ave, Coder City',
    imageKey: 'office',
  ),
  _LocationSeed(
    id: 'loc_sample_lakehouse',
    name: 'Lakehouse Retreat',
    description: 'Vacation property by the lake.',
    address: '789 Shore Ln, Mockington',
    imageKey: null,
  ),
];

const List<_RoomSeed> _kRoomSeeds = [
  // Home
  _RoomSeed(
    locationId: 'loc_sample_home',
    name: 'Kitchen',
    description: 'Recently renovated.',
    imageKey: 'kitchen',
  ),
  _RoomSeed(
    locationId: 'loc_sample_home',
    name: 'Living Room',
    description: 'TV + fireplace.',
    imageKey: 'livingRoom',
  ),
  _RoomSeed(
    locationId: 'loc_sample_home',
    name: 'Master Bedroom',
    description: 'En-suite.',
    imageKey: null,
  ),

  // Office
  _RoomSeed(
    locationId: 'loc_sample_office',
    name: 'Main Office Area',
    description: 'Open plan.',
    imageKey: 'officeRoom',
  ),
  _RoomSeed(
    locationId: 'loc_sample_office',
    name: 'Server Room',
    description: 'Needs better cooling.',
    imageKey: 'serverRoom',
  ),
  _RoomSeed(
    locationId: 'loc_sample_office',
    name: 'Meeting Room Alpha',
    description: 'VC ready.',
    imageKey: null,
  ),
];

/// Containers to create in every room
const List<_ContainerSeed> _kPerRoomContainerSeeds = [
  _ContainerSeed(
    key: 'boxA',
    nameTemplate: '{room} Box A',
    descriptionTemplate: 'General storage for {room}.',
    imageKey: 'box',
  ),
  _ContainerSeed(
    key: 'boxB',
    nameTemplate: '{room} Box B',
    descriptionTemplate: 'Secondary storage for {room}.',
    imageKey: 'bin',
  ),
  _ContainerSeed(
    key: 'smallParts',
    parentKey: 'boxA',
    nameTemplate: 'Small Parts',
    descriptionTemplate: 'Screws, connectors, adapters.',
    imageKey: 'toolbox',
  ),
];

/// Items to create in every room
const List<_ItemSeed> _kPerRoomItemSeeds = [
  // room-level
  _ItemSeed(
    nameTemplate: 'Floor Lamp',
    descriptionTemplate: 'Warm light for the {room}.',
    imageKey: 'lamp',
  ),
  _ItemSeed(
    nameTemplate: 'Spare Chair',
    descriptionTemplate: 'Occasional seating.',
    imageKey: 'chair',
  ),
  _ItemSeed(
    nameTemplate: 'Reading Stack',
    descriptionTemplate: 'Assorted books and magazines.',
    imageKey: 'book',
  ),

  // in Box A
  _ItemSeed(
    containerKey: 'boxA',
    nameTemplate: 'Router',
    descriptionTemplate: 'Backup router — keep firmware updated.',
    imageKey: 'router',
  ),
  _ItemSeed(
    containerKey: 'boxA',
    nameTemplate: 'USB Keyboard',
    descriptionTemplate: 'Spare wired keyboard.',
    imageKey: 'keyboard',
  ),

  // in Box B
  _ItemSeed(
    containerKey: 'boxB',
    nameTemplate: 'Coffee Mugs',
    descriptionTemplate: 'A few ceramic mugs.',
    imageKey: 'mug',
  ),

  // in Small Parts
  _ItemSeed(
    containerKey: 'smallParts',
    nameTemplate: 'Assorted Screws',
    descriptionTemplate: 'Wood screws, M3–M5 machine screws.',
    imageKey: null,
  ),
];

// -----------------------------------------------------------------------------
// Image asset maps
// -----------------------------------------------------------------------------

const Map<String, String> _kLocationImageAssets = {
  'home': 'assets/images/sample/locations/home.jpg',
  'office': 'assets/images/sample/locations/office.jpg',
};

const Map<String, String> _kRoomImageAssets = {
  'kitchen': 'assets/images/sample/rooms/kitchen.jpg',
  'livingRoom': 'assets/images/sample/rooms/living_room.jpg',
  'officeRoom': 'assets/images/sample/rooms/office_room.jpg',
  'serverRoom': 'assets/images/sample/rooms/server_room.jpg',
};

const Map<String, String> _kContainerImageAssets = {
  'box': 'assets/images/sample/containers/box.jpg',
  'shelf': 'assets/images/sample/containers/shelf.jpg',
  'toolbox': 'assets/images/sample/containers/toolbox.jpg',
  'bin': 'assets/images/sample/containers/bin.jpg',
};

const Map<String, String> _kItemImageAssets = {
  'lamp': 'assets/images/sample/items/lamp.jpg',
  'chair': 'assets/images/sample/items/chair.jpg',
  'book': 'assets/images/sample/items/book.jpg',
  'mug': 'assets/images/sample/items/mug.jpg',
  'router': 'assets/images/sample/items/router.jpg',
  'keyboard': 'assets/images/sample/items/keyboard.jpg',
};

// -----------------------------------------------------------------------------
// Populator
// -----------------------------------------------------------------------------

class SampleDataPopulator {
  final IDataService dataService;
  final IImageDataService? imageDataService;
  final SampleOptions options;

  late final math.Random _rng;

  SampleDataPopulator({required this.dataService, this.imageDataService, SampleOptions? options})
    : options = options ?? const SampleOptions() {
    _rng = math.Random(this.options.randomSeed ?? DateTime.now().millisecondsSinceEpoch);
  }

  // Orchestrator --------------------------------------------------------------

  Future<void> populate() async {
    _logger.info("Starting sample data population...");

    if (options.clearExistingData) {
      await _wipeAll(clearImages: options.clearImages);
    }

    final locationGuids = await _buildImagePool(_kLocationImageAssets);
    final roomGuids = await _buildImagePool(_kRoomImageAssets);
    final containerGuids = await _buildImagePool(_kContainerImageAssets);
    final itemGuids = await _buildImagePool(_kItemImageAssets);

    if (options.includeBaseSeeds) {
      await _populateLocations(_kLocationSeeds, locationGuids);
      await _populateRooms(_kRoomSeeds, roomGuids);
    }

    // Create containers + items per room for every location seed
    for (final loc in _kLocationSeeds) {
      await _populateContainersAndItemsForLocation(
        locationId: loc.id,
        containerGuidPool: containerGuids,
        itemGuidPool: itemGuids,
      );
    }

    _logger.info("Sample data population complete.");
  }

  // Step 1: wipe --------------------------------------------------------------

  Future<void> _wipeAll({required bool clearImages}) async {
    await dataService.clearAllData();
    _logger.info("Existing data cleared via IDataService.");
    if (clearImages && imageDataService != null) {
      try {
        _logger.info("Clearing all user images via IImageDataService...");
        await imageDataService!.deleteAllImages();
        _logger.info("Successfully cleared all user images.");
      } catch (e, s) {
        _logger.severe("Error clearing user images during population", e, s);
      }
    } else if (imageDataService == null) {
      _logger.info("IImageDataService is null. Skipping clearing of user images.");
    }
  }

  // Step 2: image pools -------------------------------------------------------

  Future<Map<String, List<String>>> _buildImagePool(Map<String, String> assetMap) async {
    if (imageDataService == null) return {};
    final out = <String, List<String>>{};
    for (final entry in assetMap.entries) {
      out[entry.key] = await _processAndSaveSampleImage(entry.value, entry.key);
    }
    return out;
  }

  // Step 3: locations ---------------------------------------------------------

  Future<void> _populateLocations(
    List<_LocationSeed> seeds,
    Map<String, List<String>> locationGuidPool,
  ) async {
    for (final s in seeds) {
      final guids = _pickFromPool(locationGuidPool, s.imageKey, count: 1);
      try {
        await dataService.addLocation(
          Location(
            id: s.id,
            name: s.name,
            description: s.description,
            address: s.address,
            imageGuids: guids,
          ),
        );
        _logger.finer("Added sample location: ${s.name}");
      } catch (e) {
        _logger.warning("Failed to add sample location '${s.name}'", e);
      }
    }
  }

  // Step 4: rooms -------------------------------------------------------------

  Future<void> _populateRooms(List<_RoomSeed> seeds, Map<String, List<String>> roomGuidPool) async {
    var count = 0;
    for (final s in seeds) {
      final guids = _pickFromPool(roomGuidPool, s.imageKey, count: 1);
      try {
        await dataService.addRoom(
          Room(
            name: s.name,
            description: s.description,
            locationId: s.locationId,
            imageGuids: guids,
          ),
        );
        count++;
        _logger.finer("Added sample room: ${s.name} to location ${s.locationId}");
      } catch (e) {
        _logger.warning("Failed to add sample room '${s.name}'", e);
      }
    }
    _logger.info("$count sample rooms processed.");
  }

  // Step 5: per-room containers & items (base + randomized extras) -----------

  Future<void> _populateContainersAndItemsForLocation({
    required String locationId,
    required Map<String, List<String>> containerGuidPool,
    required Map<String, List<String>> itemGuidPool,
  }) async {
    final rooms = await dataService.getRoomsForLocation(locationId);
    if (rooms.isEmpty) {
      _logger.info('No rooms for location $locationId — skipping containers/items.');
      return;
    }

    for (final room in rooms) {
      final roomId = room.id;
      final roomName = room.name;
      _logger.info('Populating containers & items for room: $roomName (id=$roomId)');

      // 1) Containers (base)
      final created = <String, Container>{};
      if (options.includeBaseSeeds) {
        for (final cs in _kPerRoomContainerSeeds) {
          final parentId = (cs.parentKey == null) ? null : created[cs.parentKey!]!.id;
          final guids = _maybeRandomImage(containerGuidPool, options.containerImageChance);

          final c = await dataService.addContainer(
            Container(
              roomId: roomId,
              parentContainerId: parentId,
              name: cs.nameTemplate.replaceAll('{room}', roomName),
              description: cs.descriptionTemplate?.replaceAll('{room}', roomName),
              imageGuids: guids,
            ),
          );
          created[cs.key] = c;
        }
      }

      // 1b) Containers (random extra top-level)
      final extraTop = <Container>[];
      for (var i = 0; i < options.extraTopLevelContainersPerRoom; i++) {
        final name = _randomContainerName(roomName);
        final guids = _maybeRandomImage(containerGuidPool, options.containerImageChance);
        final c = await dataService.addContainer(
          Container(
            roomId: roomId,
            name: name,
            description: _randomContainerDesc(roomName),
            imageGuids: guids,
          ),
        );
        extraTop.add(c);
      }

      // 1c) Child containers per top-level (base + extra)
      final allTop = [...created.values.where((c) => c.parentContainerId == null), ...extraTop];
      for (final top in allTop) {
        for (var i = 0; i < options.extraChildContainersPerTopLevel; i++) {
          final guids = _maybeRandomImage(containerGuidPool, options.containerImageChance);
          await dataService.addContainer(
            Container(
              roomId: roomId,
              parentContainerId: top.id,
              name: _randomChildContainerName(),
              description: _randomChildContainerDesc(),
              imageGuids: guids,
            ),
          );
        }
      }

      // 2) Items (base)
      if (options.includeBaseSeeds) {
        for (final iseed in _kPerRoomItemSeeds) {
          final containerId = (iseed.containerKey == null)
              ? null
              : created[iseed.containerKey!]!.id;
          final guids = _maybeRandomImage(
            itemGuidPool,
            options.itemImageChance,
            exactKey: iseed.imageKey,
          );
          await dataService.addItem(
            Item(
              roomId: roomId,
              containerId: containerId,
              name: iseed.nameTemplate.replaceAll('{room}', roomName),
              description: iseed.descriptionTemplate?.replaceAll('{room}', roomName),
              imageGuids: guids,
            ),
          );
        }
      }

      // 2b) Random items in room
      for (var i = 0; i < options.extraItemsPerRoom; i++) {
        final guids = _maybeRandomImage(itemGuidPool, options.itemImageChance);
        await dataService.addItem(
          Item(
            roomId: roomId,
            name: _randomItemName(),
            description: _randomItemDesc(),
            imageGuids: guids,
          ),
        );
      }

      // 2c) Random items in each container (top-level + all descendants)
      final allContainers = await _allContainersDeep(roomId);
      for (final c in allContainers) {
        for (var i = 0; i < options.extraItemsPerContainer; i++) {
          final guids = _maybeRandomImage(itemGuidPool, options.itemImageChance);
          await dataService.addItem(
            Item(
              roomId: roomId,
              containerId: c.id,
              name: _randomItemName(),
              description: _randomItemDesc(),
              imageGuids: guids,
            ),
          );
        }
      }
    }
  }

  // Utilities ----------------------------------------------------------------

  Future<List<Container>> _allContainersDeep(String roomId) async {
    final result = <Container>[];
    final queue = <Container>[];

    // Start with top-level
    final tops = await dataService.getRoomContainers(roomId);
    result.addAll(tops);
    queue.addAll(tops);

    // Breadth-first over descendants
    while (queue.isNotEmpty) {
      final parent = queue.removeLast();
      final children = await dataService.getChildContainers(parent.id);
      if (children.isEmpty) continue;
      result.addAll(children);
      queue.addAll(children);
    }
    return result;
  }

  List<String> _pickFromPool(Map<String, List<String>> pool, String? key, {int count = 1}) {
    if (key == null) return const [];
    final list = pool[key];
    if (list == null || list.isEmpty) return const [];
    final n = count.clamp(0, list.length);
    return List<String>.unmodifiable(list.take(n));
  }

  List<String> _maybeRandomImage(
    Map<String, List<String>> pool,
    double probability, {
    String? exactKey,
  }) {
    if (imageDataService == null || pool.isEmpty) return const [];
    if (_rng.nextDouble() > probability) return const [];

    if (exactKey != null && pool[exactKey]?.isNotEmpty == true) {
      return List<String>.unmodifiable(pool[exactKey]!);
    }

    // pick a random entry
    final keys = pool.keys.toList(growable: false);
    final k = keys[_rng.nextInt(keys.length)];
    final list = pool[k]!;
    if (list.isEmpty) return const [];
    return List<String>.unmodifiable(list.take(1));
  }

  // ---------- Random text bits (simple + readable) --------------------------

  static const _adjectives = [
    'Blue',
    'Red',
    'Green',
    'Black',
    'White',
    'Clear',
    'Heavy',
    'Light',
    'Slim',
    'Wide',
    'Soft',
    'Hard',
    'Spare',
    'Extra',
    'Old',
    'New',
  ];

  static const _containerNouns = [
    'Box',
    'Bin',
    'Crate',
    'Case',
    'Tub',
    'Chest',
    'Drawer',
    'Tray',
    'Caddy',
  ];
  static const _childContainerNouns = [
    'Small Parts',
    'Cables',
    'Adapters',
    'Tools',
    'Craft',
    'Office Supplies',
  ];

  static const _itemNouns = [
    'Cable',
    'Adapter',
    'Notebook',
    'Pen',
    'Screwdriver',
    'Tape',
    'Charger',
    'Mouse',
    'Headphones',
    'Plug',
    'Bulb',
    'Battery',
    'Hose',
    'Clamp',
    'Marker',
    'Rag',
  ];

  String _randomContainerName(String roomName) {
    final adj = _adjectives[_rng.nextInt(_adjectives.length)];
    final noun = _containerNouns[_rng.nextInt(_containerNouns.length)];
    return '$roomName $adj $noun';
  }

  String _randomContainerDesc(String roomName) {
    return 'Assorted storage for $roomName.';
  }

  String _randomChildContainerName() {
    return _childContainerNouns[_rng.nextInt(_childContainerNouns.length)];
  }

  String _randomChildContainerDesc() {
    return 'Miscellaneous small items.';
  }

  String _randomItemName() {
    final adj = _adjectives[_rng.nextInt(_adjectives.length)];
    final noun = _itemNouns[_rng.nextInt(_itemNouns.length)];
    return '$adj $noun';
  }

  String _randomItemDesc() {
    return 'Sample item seeded for UI testing.';
  }

  // ---------- File & image helpers (existing) -------------------------------

  Future<File?> _assetToTempFile(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFileName = '${_uuid.v4()}-${assetPath.split('/').last}';
      final file = File('${tempDir.path}/$tempFileName');
      await file.writeAsBytes(
        byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
      );
      _logger.finer('Asset $assetPath copied to temporary file ${file.path}');
      return file;
    } catch (e) {
      _logger.warning('Failed to convert asset $assetPath to temporary file', e);
      return null;
    }
  }

  Future<List<String>> _processAndSaveSampleImage(
    String assetPath,
    String imageFriendlyName,
  ) async {
    final guids = <String>[];
    if (imageDataService == null) {
      _logger.info("IImageDataService is null, skipping image processing for $imageFriendlyName.");
      return guids;
    }

    final tempImageFile = await _assetToTempFile(assetPath);
    if (tempImageFile == null) {
      _logger.warning("Could not create temporary file for asset $assetPath ($imageFriendlyName).");
      return guids;
    }

    try {
      final guid = await imageDataService!.saveImage(tempImageFile);
      guids.add(guid);
      _logger.info("Sample '$imageFriendlyName' ($assetPath) saved with GUID: $guid");
    } catch (e) {
      _logger.warning("Failed to save sample asset '$assetPath' via IImageDataService", e);
    } finally {
      try {
        if (await tempImageFile.exists()) {
          await tempImageFile.delete();
          _logger.finer('Deleted temp file ${tempImageFile.path} for $imageFriendlyName');
        }
      } catch (deleteError) {
        _logger.warning(
          "Failed to delete temp file ${tempImageFile.path} for $imageFriendlyName: $deleteError",
        );
      }
    }
    return guids;
  }
}
