// test/utils/mocks.dart
import 'package:mockito/annotations.dart';

// Contracts you commonly mock
import 'package:stuff/services/contracts/data_service_interface.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/services/contracts/location_service_interface.dart';
import 'package:stuff/services/contracts/permission_service_interface.dart';
import 'package:stuff/services/contracts/image_picker_service_interface.dart';
import 'package:stuff/services/contracts/temporary_file_service_interface.dart';

// Flutter / router things you might mock
import 'package:flutter/material.dart' show NavigatorObserver;

@GenerateNiceMocks([
  MockSpec<IDataService>(),
  MockSpec<IImageDataService>(),
  MockSpec<ILocationService>(),
  MockSpec<IPermissionService>(),
  MockSpec<IImagePickerService>(),
  MockSpec<ITemporaryFileService>(),
  MockSpec<NavigatorObserver>(),
  MockSpec<TempSession>(),
])
// ignore: unused_import
import 'mocks.mocks.dart';

// Re-export generated classes so tests only import this file.
export 'mocks.mocks.dart';
