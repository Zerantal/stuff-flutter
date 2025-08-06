import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Your project imports - adjust paths as necessary
import 'package:stuff/core/helpers/image_picking_and_processing_helper.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/core/image_source_type_enum.dart';
import 'package:stuff/services/image_picker_service_interface.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import 'package:stuff/services/temporary_file_service_interface.dart';

import '../../utils/test_logger_manager.dart';

// Generate mocks for your interfaces
@GenerateMocks([
  IImagePickerService,
  IImageDataService,
  ITemporaryFileService,
  File,
  Directory,
])
import 'image_picking_and_processing_helper_test.mocks.dart'; // Generated file

void main() {
  late MockIImagePickerService mockImagePickerService;
  late MockIImageDataService mockImageDataService;
  late MockITemporaryFileService mockTempFileService;
  late MockDirectory mockSessionTempDir;
  late MockFile mockPickedFile;
  late MockFile mockCopiedTempFile;
  late Logger logger;
  late TestLoggerManager loggerManager;

  late ImagePickingAndProcessingHelper helper;

  setUp(() {
    mockImagePickerService = MockIImagePickerService();
    mockImageDataService = MockIImageDataService();
    mockTempFileService = MockITemporaryFileService();
    mockSessionTempDir = MockDirectory();
    mockPickedFile = MockFile();
    mockCopiedTempFile = MockFile();

    logger = Logger('TestImageHelper');
    loggerManager = TestLoggerManager(loggerName: 'TestImageHelper');
    loggerManager.startCapture();

    // Default mock behaviors
    when(mockPickedFile.path).thenReturn('/fake/picker_cache/picked_image.jpg');
    when(mockPickedFile.delete()).thenAnswer((_) async => mockPickedFile);
    when(mockPickedFile.exists()).thenAnswer((_) async => true);

    when(
      mockCopiedTempFile.path,
    ).thenReturn('/fake/session_temp/copied_image.jpg');

    when(mockSessionTempDir.path).thenReturn('/fake/session_temp');

    when(
      mockImagePickerService.pickImageFromCamera(),
    ).thenAnswer((_) async => mockPickedFile);
    when(
      mockImagePickerService.pickImageFromGallery(),
    ).thenAnswer((_) async => mockPickedFile);

    when(
      mockImageDataService.saveUserImage(any),
    ).thenAnswer((_) async => 'test-guid-123');

    when(
      mockTempFileService.copyToTempDir(any, any),
    ).thenAnswer((_) async => mockCopiedTempFile);
  });

  tearDown(() {
    loggerManager.stopCapture();
  });

  group('ImagePickingAndProcessingHelper Tests', () {
    group('Argument Validation', () {
      test(
        'throws ArgumentError if not directSave, imageDataService is null, and sessionTempDir is null, logs SEVERE',
        () {
          helper = ImagePickingAndProcessingHelper(
            imagePickerService: mockImagePickerService,
            imageDataService: null, // imageDataService is null
            tempFileService: mockTempFileService,
            logger: logger,
          );

          expect(
            () => helper.pickImage(
              source: ImageSourceType.camera,
              directSaveWithImageDataService: false, // not direct save
              sessionTempDir: null, // sessionTempDir is null
            ),
            throwsA(isA<ArgumentError>()),
          );

          expect(
            loggerManager.findLogWithMessage(
              'Helper: sessionTempDir must be provided if not performing a direct save or if '
              'ImageDataService is null (fallback).',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
        },
      );

      test(
        'throws ArgumentError if directSave, imageDataService is null (fallback), and sessionTempDir is null, logs SEVERE after WARNING',
        () {
          helper = ImagePickingAndProcessingHelper(
            imagePickerService: mockImagePickerService,
            imageDataService: null, // imageDataService is null
            tempFileService: mockTempFileService,
            logger: logger,
          );

          expect(
            () => helper.pickImage(
              source: ImageSourceType.camera,
              directSaveWithImageDataService: true, // direct save requested
              sessionTempDir: null, // sessionTempDir is null for fallback
            ),
            throwsA(isA<ArgumentError>()),
          );
          expect(
            loggerManager.findLogWithMessage(
              'Helper: directSaveWithImageDataService is true, but ImageDataService is null. '
              'Fallback to temp copy.',
              level: Level.WARNING,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              'Helper: sessionTempDir must be provided if not performing a direct save or if '
              'ImageDataService is null (fallback).',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
        },
      );
    });

    group('Direct Save Logic (imageDataService is available)', () {
      setUp(() {
        // imageDataService is available for these tests
        helper = ImagePickingAndProcessingHelper(
          imagePickerService: mockImagePickerService,
          imageDataService: mockImageDataService,
          tempFileService: mockTempFileService,
          logger: logger,
        );
      });

      test(
        'picks from camera, direct saves, returns GuidIdentifier, deletes picker cache',
        () async {
          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: true,
            // sessionTempDir not needed for direct save
          );

          expect(result, isA<GuidIdentifier>());
          expect((result as GuidIdentifier).guid, 'test-guid-123');
          verify(mockImagePickerService.pickImageFromCamera()).called(1);
          verify(mockImageDataService.saveUserImage(mockPickedFile)).called(1);
          verify(mockPickedFile.delete()).called(1);
          verifyNever(mockTempFileService.copyToTempDir(any, any));
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Image saved with GUID: test-guid-123.',
              level: Level.INFO,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Deleted picker's temp file: ${mockPickedFile.path}",
              level: Level.FINER,
            ),
            isNotNull,
          );
        },
      );

      test(
        'picks from gallery, direct saves, returns GuidIdentifier, deletes picker cache',
        () async {
          final result = await helper.pickImage(
            source: ImageSourceType.gallery,
            directSaveWithImageDataService: true,
          );

          expect(result, isA<GuidIdentifier>());
          expect((result as GuidIdentifier).guid, 'test-guid-123');
          verify(mockImagePickerService.pickImageFromGallery()).called(1);
          verify(mockImageDataService.saveUserImage(mockPickedFile)).called(1);
          verify(mockPickedFile.delete()).called(1);
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Image saved with GUID: test-guid-123.',
              level: Level.INFO,
            ),
            isNotNull,
          );
        },
      );

      test('direct save, logs WARNING if deleting picker cache fails', () async {
        when(mockPickedFile.delete()).thenThrow(Exception("Disk full"));

        final result = await helper.pickImage(
          source: ImageSourceType.camera,
          directSaveWithImageDataService: true,
        );

        expect(result, isA<GuidIdentifier>());
        verify(mockPickedFile.delete()).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Helper: Failed to delete picker's temp file ${mockPickedFile.path} after direct save: Exception: Disk full",
            level: Level.WARNING,
          ),
          isNotNull,
        );
      });
    });

    group('Temporary Copy Logic (directSave is false OR imageDataService is null)', () {
      test(
        'directSave is false: picks, copies to temp, returns TempFileIdentifier, deletes picker cache',
        () async {
          // imageDataService IS available, but directSave is false
          helper = ImagePickingAndProcessingHelper(
            imagePickerService: mockImagePickerService,
            imageDataService: mockImageDataService,
            tempFileService: mockTempFileService,
            logger: logger,
          );

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: false,
            sessionTempDir: mockSessionTempDir,
          );

          expect(result, isA<TempFileIdentifier>());
          expect((result as TempFileIdentifier).file, mockCopiedTempFile);
          verify(mockImagePickerService.pickImageFromCamera()).called(1);
          verify(
            mockTempFileService.copyToTempDir(
              mockPickedFile,
              mockSessionTempDir,
            ),
          ).called(1);
          verify(mockPickedFile.delete()).called(1);
          verifyNever(mockImageDataService.saveUserImage(any));
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Image copied to session temp: ${mockCopiedTempFile.path}",
              level: Level.INFO,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Deleted picker's temp file: ${mockPickedFile.path} after copying to session.",
              level: Level.FINER,
            ),
            isNotNull,
          );
        },
      );

      test(
        'imageDataService is null (fallback): picks, copies to temp, returns TempFileIdentifier, deletes picker cache, logs WARNING for fallback',
        () async {
          helper = ImagePickingAndProcessingHelper(
            imagePickerService: mockImagePickerService,
            imageDataService: null, // imageDataService is NULL
            tempFileService: mockTempFileService,
            logger: logger,
          );

          final result = await helper.pickImage(
            source: ImageSourceType.gallery,
            directSaveWithImageDataService:
                true, // Requested direct, but will fallback
            sessionTempDir: mockSessionTempDir,
          );

          expect(result, isA<TempFileIdentifier>());
          expect((result as TempFileIdentifier).file, mockCopiedTempFile);
          verify(mockImagePickerService.pickImageFromGallery()).called(1);
          verify(
            mockTempFileService.copyToTempDir(
              mockPickedFile,
              mockSessionTempDir,
            ),
          ).called(1);
          verify(mockPickedFile.delete()).called(1);
          verifyNever(
            mockImageDataService.saveUserImage(any),
          ); // Ensure it wasn't called
          expect(
            loggerManager.findLogWithMessage(
              'Helper: directSaveWithImageDataService is true, but ImageDataService is null. '
              'Fallback to temp copy.',
              level: Level.WARNING,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Image copied to session temp: ${mockCopiedTempFile.path}",
              level: Level.INFO,
            ),
            isNotNull,
          );
        },
      );

      test('temp copy, logs WARNING if deleting picker cache fails', () async {
        helper = ImagePickingAndProcessingHelper(
          imagePickerService: mockImagePickerService,
          imageDataService: mockImageDataService, // Available, but not used
          tempFileService: mockTempFileService,
          logger: logger,
        );
        when(mockPickedFile.delete()).thenThrow(Exception("Disk space issue"));

        final result = await helper.pickImage(
          source: ImageSourceType.camera,
          directSaveWithImageDataService: false,
          sessionTempDir: mockSessionTempDir,
        );

        expect(result, isA<TempFileIdentifier>());
        verify(mockPickedFile.delete()).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Helper: Failed to delete picker's temp file ${mockPickedFile.path} after copying to session: Exception: Disk space issue",
            level: Level.WARNING,
          ),
          isNotNull,
        );
      });
    });

    group('Image Picker Failures', () {
      setUp(() {
        helper = ImagePickingAndProcessingHelper(
          imagePickerService: mockImagePickerService,
          imageDataService:
              mockImageDataService, // Assume available for some tests
          tempFileService: mockTempFileService,
          logger: logger,
        );
      });

      test(
        'returns null if image picker returns null (e.g., user cancelled)',
        () async {
          when(
            mockImagePickerService.pickImageFromCamera(),
          ).thenAnswer((_) async => null);

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService:
                true, // Does not matter for this failure
          );

          expect(result, isNull);
          verify(mockImagePickerService.pickImageFromCamera()).called(1);
          verifyNever(mockImageDataService.saveUserImage(any));
          verifyNever(mockTempFileService.copyToTempDir(any, any));
          verifyNever(mockPickedFile.delete());
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Image picking cancelled or failed (null file returned from picker).',
              level: Level.INFO,
            ),
            isNotNull,
          );
        },
      );

      test(
        'returns null and logs SEVERE if image picker throws, cleans up picked file if exists',
        () async {
          final exception = Exception('Picker crashed');
          when(
            mockImagePickerService.pickImageFromCamera(),
          ).thenThrow(exception);
          // In this scenario, pickedFileFromPicker would remain null or not get assigned before error

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: false,
            sessionTempDir: mockSessionTempDir,
          );

          expect(result, isNull);
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Error during pickImage: $exception',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
          // Since pickedFileFromPicker is assigned *after* the await, if picker throws, it will be null.
          // The cleanup logic `if (pickedFileFromPicker != null && await pickedFileFromPicker.exists())` will not run.
          verifyNever(mockPickedFile.delete());
        },
      );
    });

    group('Service Failures (Save/Copy/Delete)', () {
      setUp(() {
        helper = ImagePickingAndProcessingHelper(
          imagePickerService: mockImagePickerService,
          imageDataService: mockImageDataService,
          tempFileService: mockTempFileService,
          logger: logger,
        );
      });

      test(
        'returns null, logs SEVERE, and attempts cleanup if _imageDataService.saveUserImage throws',
        () async {
          final exception = Exception('DB save failed');
          when(
            mockImageDataService.saveUserImage(mockPickedFile),
          ).thenThrow(exception);

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: true, // Attempt direct save
          );

          expect(result, isNull);
          verify(mockPickedFile.delete()).called(1); // Cleanup attempt
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Error during pickImage: $exception',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Cleaned up picker's temp file after error: ${mockPickedFile.path}",
              level: Level.INFO,
            ),
            isNotNull,
          );
        },
      );

      test(
        'returns null, logs SEVERE, and attempts cleanup if _tempFileService.copyToTempDir throws',
        () async {
          final exception = Exception('Copy failed, disk full');
          when(
            mockTempFileService.copyToTempDir(
              mockPickedFile,
              mockSessionTempDir,
            ),
          ).thenThrow(exception);

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: false, // Attempt copy
            sessionTempDir: mockSessionTempDir,
          );

          expect(result, isNull);
          verify(mockPickedFile.delete()).called(1); // Cleanup attempt
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Error during pickImage: $exception',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Cleaned up picker's temp file after error: ${mockPickedFile.path}",
              level: Level.INFO,
            ),
            isNotNull,
          );
        },
      );

      test(
        'logs WARNING if cleanup of picked file fails after another error',
        () async {
          final primaryException = Exception('DB save failed');
          when(
            mockImageDataService.saveUserImage(mockPickedFile),
          ).thenThrow(primaryException);

          final cleanupException = Exception('Cleanup disk error');
          when(mockPickedFile.delete()).thenThrow(cleanupException);

          final result = await helper.pickImage(
            source: ImageSourceType.camera,
            directSaveWithImageDataService: true, // Attempt direct save
          );
          expect(result, isNull);
          expect(
            loggerManager.findLogWithMessage(
              'Helper: Error during pickImage: $primaryException',
              level: Level.SEVERE,
            ),
            isNotNull,
          );
          expect(
            loggerManager.findLogWithMessage(
              "Helper: Failed to cleanup picker's temp file ${mockPickedFile.path} after an error: $cleanupException",
              level: Level.WARNING,
            ),
            isNotNull,
          );
        },
      );
    });
  });
}
