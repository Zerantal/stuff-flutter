import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:stuff/services/impl/flutter_image_picker_service.dart';
import 'package:stuff/services/permission_service_interface.dart';
import '../../utils/test_logger_manager.dart';

// import generated mock file
import 'flutter_image_picker_service_test.mocks.dart';

@GenerateMocks([ImagePicker, IPermissionService])
void main() {
  late FlutterImagePickerService service;
  late MockImagePicker mockImagePicker;
  late MockIPermissionService mockPermissionService;
  late TestLoggerManager loggerManager;

  setUp(() {
    mockImagePicker = MockImagePicker();
    mockPermissionService = MockIPermissionService();
    service = FlutterImagePickerService(
      imagePicker: mockImagePicker,
      permissionService: mockPermissionService,
    );
    loggerManager = TestLoggerManager();
    loggerManager.startCapture();
  });

  tearDown(() {
    loggerManager.stopCapture();
  });

  group('pickImageFromCamera', () {
    const double defaultMaxWidth = kDefaultImageMaxWidth;
    const double defaultMaxHeight = kDefaultImageMaxHeight;
    const int defaultImageQuality = kDefaultImageQuality;
    final mockXFile = XFile('fake_path/camera_image.jpg');

    test('should throw Exception and log warning if camera permission denied', () async {
      // ARRANGE
      when(mockPermissionService.requestCameraPermission()).thenAnswer((_) async => false);

      // ACT & ASSERT
      File? result = await service.pickImageFromCamera();
      expect(result, isNull);

      // Verify no interaction with image picker if permission denied
      verifyNever(
        mockImagePicker.pickImage(
          source: anyNamed('source'),
          maxWidth: anyNamed('maxWidth'),
          maxHeight: anyNamed('maxHeight'),
          imageQuality: anyNamed('imageQuality'),
        ),
      );

      await Future.delayed(Duration.zero); // Allow logs to process

      await pumpEventQueue();

      expect(
        loggerManager.findLogWithMessage(
          'Permission denied for ImageSource.camera',
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('should return null and not throw if permission granted but no image picked', () async {
      // ARRANGE
      when(mockPermissionService.requestCameraPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).thenAnswer((_) async => null); // ImagePicker returns null

      // ACT
      final File? result = await service.pickImageFromCamera(
        maxWidth: defaultMaxWidth,
        maxHeight: defaultMaxHeight,
        imageQuality: defaultImageQuality,
      );

      // ASSERT
      expect(result, isNull);
      verify(mockPermissionService.requestCameraPermission()).called(1);
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).called(1);
    });

    test('should return File if permission granted and image is picked', () async {
      // ARRANGE
      when(mockPermissionService.requestCameraPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).thenAnswer((_) async => mockXFile);

      // ACT
      final File? result = await service.pickImageFromCamera(
        maxWidth: defaultMaxWidth,
        maxHeight: defaultMaxHeight,
        imageQuality: defaultImageQuality,
      );

      // ASSERT
      expect(result, isA<File>());
      expect(result?.path, equals(mockXFile.path));
      verify(mockPermissionService.requestCameraPermission()).called(1);
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).called(1);
    });

    test('should use provided parameters when picking image', () async {
      // ARRANGE
      const customMaxWidth = 800.0;
      const customMaxHeight = 600.0;
      const customImageQuality = 70;
      when(mockPermissionService.requestCameraPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: customMaxWidth,
          maxHeight: customMaxHeight,
          imageQuality: customImageQuality,
        ),
      ).thenAnswer((_) async => mockXFile);

      // ACT
      await service.pickImageFromCamera(
        maxWidth: customMaxWidth,
        maxHeight: customMaxHeight,
        imageQuality: customImageQuality,
      );

      // ASSERT
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: customMaxWidth,
          maxHeight: customMaxHeight,
          imageQuality: customImageQuality,
        ),
      ).called(1);
    });

    test('should rethrow and log error if ImagePicker throws an exception', () async {
      // ARRANGE
      final exception = Exception('ImagePicker failed');
      when(mockPermissionService.requestCameraPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).thenThrow(exception);

      // ACT & ASSERT
      expect(
        () => service.pickImageFromCamera(),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'toString', 'Exception: ImagePicker failed'),
        ),
      );
      await Future.delayed(Duration.zero); // Allow logs to process
      expect(
        loggerManager.findLogWithMessage(
          'Error picking image from ImageSource.camera',
          error: exception,
          level: Level.SEVERE,
        ),
        isNotNull,
      );
    });

    test(
      'should rethrow and log error if PermissionService throws during camera permission request',
      () async {
        // ARRANGE
        final exception = Exception('Permission service failed');
        when(mockPermissionService.requestCameraPermission()).thenThrow(exception);

        // ACT & ASSERT
        expect(
          () => service.pickImageFromCamera(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Permission service failed',
            ),
          ),
        );
        verifyNever(
          mockImagePicker.pickImage(source: anyNamed('source')),
        ); // Ensure picker is not called
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Error picking image from ImageSource.camera',
            error: exception,
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );
  });

  group('pickImageFromGallery', () {
    const double defaultMaxWidth = kDefaultImageMaxWidth;
    const double defaultMaxHeight = kDefaultImageMaxHeight;
    const int defaultImageQuality = kDefaultImageQuality;
    final mockXFile = XFile('fake_path/gallery_image.jpg');

    test('should throw Exception and log warning if gallery permission denied', () async {
      // ARRANGE
      when(mockPermissionService.requestGalleryPermission()).thenAnswer((_) async => false);

      // ACT & ASSERT
      final File? result = await service.pickImageFromGallery();
      expect(result, isNull);

      verifyNever(mockImagePicker.pickImage(source: anyNamed('source')));

      await Future.delayed(Duration.zero);
      expect(
        loggerManager.findLogWithMessage(
          'Permission denied for ImageSource.gallery',
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('should return null if permission granted but no image picked from gallery', () async {
      // ARRANGE
      when(mockPermissionService.requestGalleryPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).thenAnswer((_) async => null);

      // ACT
      final File? result = await service.pickImageFromGallery();

      // ASSERT
      expect(result, isNull);
      verify(mockPermissionService.requestGalleryPermission()).called(1);
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).called(1);
    });

    test('should return File if permission granted and image is picked from gallery', () async {
      // ARRANGE
      when(mockPermissionService.requestGalleryPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).thenAnswer((_) async => mockXFile);

      // ACT
      final File? result = await service.pickImageFromGallery();

      // ASSERT
      expect(result, isA<File>());
      expect(result?.path, equals(mockXFile.path));
      verify(mockPermissionService.requestGalleryPermission()).called(1);
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: defaultMaxWidth,
          maxHeight: defaultMaxHeight,
          imageQuality: defaultImageQuality,
        ),
      ).called(1);
    });

    test('should use provided parameters when picking image from gallery', () async {
      // ARRANGE
      const customMaxWidth = 750.0;
      const customMaxHeight = 550.0;
      const customImageQuality = 65;
      when(mockPermissionService.requestGalleryPermission()).thenAnswer((_) async => true);
      when(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: customMaxWidth,
          maxHeight: customMaxHeight,
          imageQuality: customImageQuality,
        ),
      ).thenAnswer((_) async => mockXFile);

      // ACT
      await service.pickImageFromGallery(
        maxWidth: customMaxWidth,
        maxHeight: customMaxHeight,
        imageQuality: customImageQuality,
      );

      // ASSERT
      verify(
        mockImagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: customMaxWidth,
          maxHeight: customMaxHeight,
          imageQuality: customImageQuality,
        ),
      ).called(1);
    });

    test(
      'should rethrow and log error if ImagePicker throws during pickImageFromGallery',
      () async {
        // ARRANGE
        final exception = Exception('Gallery ImagePicker failed');
        when(mockPermissionService.requestGalleryPermission()).thenAnswer((_) async => true);
        when(
          mockImagePicker.pickImage(
            source: ImageSource.gallery,
            maxWidth: defaultMaxWidth,
            maxHeight: defaultMaxHeight,
            imageQuality: defaultImageQuality,
          ),
        ).thenThrow(exception);

        // ACT & ASSERT
        expect(
          () => service.pickImageFromGallery(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Gallery ImagePicker failed',
            ),
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Error picking image from ImageSource.gallery',
            error: exception,
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should rethrow and log error if PermissionService throws during gallery permission request',
      () async {
        // ARRANGE
        final exception = Exception('Permission service for gallery failed');
        when(mockPermissionService.requestGalleryPermission()).thenThrow(exception);

        // ACT & ASSERT
        expect(
          () => service.pickImageFromGallery(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              'Exception: Permission service for gallery failed',
            ),
          ),
        );
        verifyNever(
          mockImagePicker.pickImage(source: anyNamed('source')),
        ); // Ensure picker is not called
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Error picking image from ImageSource.gallery',
            error: exception,
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );
  });
}
