import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:stuff/services/contracts/temporary_file_service_interface.dart';
import 'package:stuff/shared/image/image_ref.dart';

class DummyTempSession extends TempSession {
  @override
  Directory get dir => throw UnimplementedError();

  @override
  Future<void> dispose({bool deleteContents = true}) => throw UnimplementedError();

  @override
  Future<File> importFile(File src, {String? preferredName, bool deleteSource = true}) =>
      throw UnimplementedError();
}

// useful dummies for tests
void registerCommonDummies() {
  provideDummy<ImageRef>(const ImageRef.asset('placeholder'));
}
