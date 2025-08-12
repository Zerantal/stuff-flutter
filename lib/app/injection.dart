// lib/app/injection.dart
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/data_service_interface.dart';
import '../services/location_service_interface.dart';
import '../services/image_picker_service_interface.dart';
import '../services/temporary_file_service_interface.dart';
import '../services/image_data_service_interface.dart';

import '../services/impl/geolocator_location_service.dart';
import '../services/impl/flutter_image_picker_service.dart';
import '../services/impl/path_provider_temporary_file_service.dart';
import '../services/impl/local_image_data_service.dart';

final Logger _log = Logger('DI');

List<SingleChildWidget> buildGlobalProviders({required IDataService dataService}) {
  return [
    Provider<IDataService>.value(value: dataService),

    // Synchronous services
    Provider<ILocationService>(create: (_) => GeolocatorLocationService()),
    Provider<IImagePickerService>(create: (_) => FlutterImagePickerService()),
    Provider<ITemporaryFileService>(create: (_) => PathProviderTemporaryFileService()),

    // Provide image data service synchronously.
    // If it has async setup, start it in the background or make methods lazy-init.
    Provider<IImageDataService>(
      create: (_) {
        _log.info("Creating LocalImageDataService...");
        final s = LocalImageDataService();
        unawaited(s.init()); // safe fire-and-forget; service should lazy ensure paths
        _log.info("LocalImageDataService created.");
        return s;
      },
    ),
  ];
}
