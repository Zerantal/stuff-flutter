// lib/app/injection.dart
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/contracts/data_service_interface.dart';
import '../services/contracts/location_service_interface.dart';
import '../services/contracts/image_picker_service_interface.dart';
import '../services/contracts/temporary_file_service_interface.dart';
import '../services/contracts/image_data_service_interface.dart';

import '../services/impl/geolocator_location_service.dart';
import '../services/impl/flutter_image_picker_service.dart';
import '../services/impl/path_provider_temporary_file_service.dart';

final Logger _log = Logger('InjectionI');

/// Provide already-initialized singletons (esp. IImageDataService).
List<SingleChildWidget> buildGlobalProviders({
  required IDataService dataService,
  required IImageDataService imageDataService,
}) {
  _log.info('Wiring global providers...');
  return [
    // Core singletons
    Provider<IDataService>.value(value: dataService),
    Provider<IImageDataService>.value(value: imageDataService),

    // Synchronous services
    Provider<ILocationService>(create: (_) => GeolocatorLocationService()),
    Provider<IImagePickerService>(create: (_) => FlutterImagePickerService()),
    Provider<ITemporaryFileService>(create: (_) => PathProviderTemporaryFileService()),
  ];
}
