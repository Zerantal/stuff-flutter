// test/viewmodels/edit_location_view_model_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:logging/logging.dart';

// Your project imports
import 'package:stuff/models/location_model.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/core/image_source_type_enum.dart';
import 'package:stuff/services/data_service_interface.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import 'package:stuff/services/location_service_interface.dart';
import 'package:stuff/services/image_picker_service_interface.dart';
import 'package:stuff/services/temporary_file_service_interface.dart';
import 'package:stuff/services/exceptions/permission_exceptions.dart';
import 'package:stuff/services/exceptions/os_service_exceptions.dart';
import 'package:stuff/viewmodels/edit_location_view_model.dart';

import '../utils/test_logger_manager.dart';
import 'edit_location_view_model_test.mocks.dart';

// Helper to listen to ChangeNotifier notifications
class NotifyListener extends Mock {
  void call();
}

@GenerateMocks([
  IDataService,
  IImageDataService,
  ILocationService,
  IImagePickerService,
  ITemporaryFileService,
  File,
  Directory,
  FormState,
  BuildContext,
  NavigatorState,
])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockIDataService mockDataService;
  late MockIImageDataService mockImageDataService;
  late MockILocationService mockLocationService;
  late MockIImagePickerService mockImagePickerService;
  late MockITemporaryFileService mockTempFileService;
  late MockDirectory mockTempDir;

  late TestLoggerManager loggerManager;
  late EditLocationViewModel viewModel;
  Location? initialLocation;

  // Helper to create the ViewModel with default mocks
  EditLocationViewModel createViewModel({
    Location? initialLoc,
    bool formShouldValidate = true,
    IImageDataService? imageDataService,
    String? nameControllerText,
  }) {
    final vm = EditLocationViewModel(
      dataService: mockDataService,
      imageDataService: imageDataService,
      locationService: mockLocationService,
      imagePickerService: mockImagePickerService,
      tempFileService: mockTempFileService,
      initialLocation: initialLoc,
      formValidator: () => formShouldValidate,
    );

    if (nameControllerText != null) {
      vm.nameController.text = nameControllerText;
    }
    return vm;
  }

  // Helper to simulate adding an image via ViewModel's API
  // Returns the File object that the ViewModel internally stores (the copied file)
  Future<TempFileIdentifier> simulatePickImageWithHelper(
    EditLocationViewModel vm, {
    ImageSourceType source = ImageSourceType.camera,
    String pickedImageName = 'picked_temp.jpg',
    String tempCopiedImageName = 'copied_temp_for_session.jpg',
  }) async {
    final mockPickedFile = MockFile();
    when(mockPickedFile.path).thenReturn('/fake/picker/$pickedImageName');

    final mockTempSessionFile = MockFile();
    when(
      mockTempSessionFile.path,
    ).thenReturn('${mockTempDir.path}/$tempCopiedImageName');

    if (source == ImageSourceType.camera) {
      when(
        mockImagePickerService.pickImageFromCamera(),
      ).thenAnswer((_) async => mockPickedFile);
    } else {
      when(
        mockImagePickerService.pickImageFromGallery(),
      ).thenAnswer((_) async => mockPickedFile);
    }

    when(
      mockTempFileService.copyToTempDir(mockPickedFile, mockTempDir),
    ).thenAnswer((_) async => mockTempSessionFile);

    if (source == ImageSourceType.camera) {
      await vm.pickImageFromCamera();
    } else {
      await vm.pickImageFromGallery();
    }

    return TempFileIdentifier(mockTempSessionFile);
  }

  setUp(() {
    mockDataService = MockIDataService();
    mockImageDataService = MockIImageDataService();
    mockLocationService = MockILocationService();
    mockImagePickerService = MockIImagePickerService();
    mockTempFileService = MockITemporaryFileService();
    mockTempDir = MockDirectory();

    when(
      mockTempFileService.createSessionTempDir(any),
    ).thenAnswer((_) async => mockTempDir);
    when(mockTempDir.path).thenReturn('/fake/temp/dir');
    when(mockTempDir.exists()).thenAnswer((_) async => true);

    when(
      mockLocationService.isServiceEnabledAndPermitted(),
    ).thenAnswer((_) async => true);

    initialLocation = null;

    loggerManager = TestLoggerManager();
    loggerManager.startCapture();
  });

  tearDown(() {
    loggerManager.stopCapture();
    viewModel.dispose();
  });

  group('Initialization', () {
    test('initializes for a new location correctly', () async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      expect(viewModel.isNewLocation, isTrue);
      expect(viewModel.nameController.text, isEmpty);
      expect(viewModel.descriptionController.text, isEmpty);
      expect(viewModel.addressController.text, isEmpty);
      expect(viewModel.currentImages, isEmpty);
      expect(viewModel.isGettingLocation, isFalse);
      expect(viewModel.deviceHasLocationService, isTrue);
      expect(viewModel.locationPermissionDenied, isFalse);
      expect(viewModel.isSaving, isFalse);
      expect(viewModel.isPickingImage, isFalse);

      verify(
        mockTempFileService.createSessionTempDir('edit_location_session'),
      ).called(1);
    });

    test('initializes for an existing location correctly', () async {
      initialLocation = Location(
        id: 'loc1',
        name: 'Test Location',
        description: 'Test Desc',
        address: '123 Test St',
        imageGuids: ['guid1', 'guid2'],
      );
      viewModel = createViewModel(initialLoc: initialLocation);
      await Future.delayed(Duration.zero);

      expect(viewModel.isNewLocation, isFalse);
      expect(viewModel.nameController.text, 'Test Location');
      expect(viewModel.descriptionController.text, 'Test Desc');
      expect(viewModel.addressController.text, '123 Test St');
      expect(viewModel.currentImages.length, 2);
      expect(viewModel.currentImages[0], isA<GuidIdentifier>());
      expect((viewModel.currentImages[0] as GuidIdentifier).guid, 'guid1');
      expect(viewModel.isSaving, isFalse);
      expect(viewModel.isPickingImage, isFalse);
      verify(
        mockTempFileService.createSessionTempDir('edit_location_session'),
      ).called(1);
    });

    test('handles failure in _initializeTempDirectory gracefully', () async {
      when(
        mockTempFileService.createSessionTempDir(any),
      ).thenThrow(Exception("Failed to create dir"));

      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      expect(
        loggerManager.findLogWithMessage(
          'Failed to initialize temporary image directory',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
      // TODO: ViewModel should still be usable, _tempDir will be null
    });
  });

  group('Location Service Status', () {
    setUp(() async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);
    });

    test(
      'refreshLocationServiceStatus updates status and notifies listeners if changed',
      () async {
        final listener = NotifyListener();
        viewModel.addListener(listener.call);

        when(
          mockLocationService.isServiceEnabledAndPermitted(),
        ).thenAnswer((_) async => false);
        await viewModel.refreshLocationServiceStatus();

        expect(viewModel.deviceHasLocationService, isFalse);
        expect(viewModel.locationPermissionDenied, isTrue);
        verify(listener.call()).called(1);

        when(
          mockLocationService.isServiceEnabledAndPermitted(),
        ).thenAnswer((_) async => true);
        await viewModel.refreshLocationServiceStatus();
        expect(viewModel.deviceHasLocationService, isTrue);
        expect(viewModel.locationPermissionDenied, isFalse);
        verify(listener.call()).called(1);

        viewModel.removeListener(listener.call);
      },
    );

    test(
      'checkLocationServiceStatus updates status but only notifies if changed',
      () async {
        final listener = NotifyListener();
        viewModel.addListener(listener.call);

        await viewModel.checkLocationServiceStatus();
        expect(viewModel.deviceHasLocationService, isTrue);
        verifyNever(listener.call());

        when(
          mockLocationService.isServiceEnabledAndPermitted(),
        ).thenAnswer((_) async => false);
        await viewModel.checkLocationServiceStatus();
        expect(viewModel.deviceHasLocationService, isFalse);
        verify(listener.call()).called(1);

        viewModel.removeListener(listener.call);
      },
    );
  });

  group('getCurrentAddress', () {
    setUp(() async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);
    });

    test('successfully gets and sets address', () async {
      final listener = NotifyListener();
      viewModel.addListener(listener.call);
      when(
        mockLocationService.getCurrentAddress(),
      ).thenAnswer((_) async => 'Test Address');

      await viewModel.getCurrentAddress();

      expect(viewModel.addressController.text, 'Test Address');
      expect(viewModel.isGettingLocation, isFalse);
      expect(viewModel.deviceHasLocationService, isTrue);
      expect(viewModel.locationPermissionDenied, isFalse);
      verify(listener.call()).called(greaterThan(0));
      viewModel.removeListener(listener.call);
    });

    test('handles LocationPermissionDeniedException', () async {
      final listener = NotifyListener();
      viewModel.addListener(listener.call);
      when(
        mockLocationService.getCurrentAddress(),
      ).thenThrow(LocationPermissionDeniedException('denied'));

      await viewModel.getCurrentAddress();

      expect(viewModel.isGettingLocation, isFalse);
      expect(viewModel.deviceHasLocationService, isFalse);
      expect(viewModel.locationPermissionDenied, isTrue);
      expect(
        loggerManager.findLogWithMessage(
          'Location permission denied',
          level: Level.WARNING,
        ),
        isNotNull,
      );
      verify(listener()).called(greaterThan(0));
      viewModel.removeListener(listener.call);
    });

    test('handles PermissionDeniedPermanentlyException', () async {
      when(
        mockLocationService.getCurrentAddress(),
      ).thenThrow(PermissionDeniedPermanentlyException('perm denied'));
      await viewModel.getCurrentAddress();
      expect(viewModel.deviceHasLocationService, isFalse);
      expect(viewModel.locationPermissionDenied, isTrue);
      expect(
        loggerManager.findLogWithMessage(
          'Location permission permanently denied',
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('handles OSServiceDisabledException', () async {
      when(mockLocationService.getCurrentAddress()).thenThrow(
        OSServiceDisabledException(
          serviceName: 'LocationService',
          message: 'disabled',
        ),
      );
      await viewModel.getCurrentAddress();
      expect(viewModel.deviceHasLocationService, isFalse);
      expect(viewModel.locationPermissionDenied, isTrue);
      expect(
        loggerManager.findLogWithMessage(
          'Location service disabled',
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('handles generic exception', () async {
      when(
        mockLocationService.getCurrentAddress(),
      ).thenThrow(Exception('generic error'));
      await viewModel.getCurrentAddress();
      expect(viewModel.isGettingLocation, isFalse);

      expect(
        loggerManager.findLogWithMessage(
          'Error getting current address',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
    });

    test('does nothing if already getting location', () async {
      final addressCompleter = Completer<String>();
      when(
        mockLocationService.getCurrentAddress(),
      ).thenAnswer((_) => addressCompleter.future);

      final call1Future = viewModel.getCurrentAddress(); // Don't await yet

      // At this point, _isGettingLocation should be true.
      // Call it again. This call should hit the guard.
      final call2Future = viewModel.getCurrentAddress(); // Don't await yet

      // Now complete the first operation
      addressCompleter.complete('Test Address');

      // Await both futures to ensure all async operations related to them are done
      await call1Future;
      await call2Future; // This future should complete quickly as it should have done nothing

      verify(mockLocationService.getCurrentAddress()).called(1);
    });
  });

  group('Image Picking (with ImagePickingAndProcessingHelper)', () {
    setUp(() async {
      viewModel = createViewModel(imageDataService: mockImageDataService);
      await Future.delayed(Duration.zero);
    });

    test(
      'pickImageFromCamera successfully adds TempFileIdentifier via helper',
      () async {
        final listener = NotifyListener();
        viewModel.addListener(listener.call);

        final expectedTempFileIdent = await simulatePickImageWithHelper(
          viewModel,
          source: ImageSourceType.camera,
        );

        expect(viewModel.isPickingImage, isFalse);
        expect(viewModel.currentImages.length, 1);
        expect(viewModel.currentImages[0], isA<TempFileIdentifier>());
        final addedImage = viewModel.currentImages[0] as TempFileIdentifier;
        expect(addedImage.file.path, expectedTempFileIdent.file.path);
        verify(listener.call()).called(
          2,
        ); // isPickingImage true, then image added & isPickingImage false
        viewModel.removeListener(listener.call);
      },
    );

    test(
      'pickImageFromGallery successfully adds TempFileIdentifier via helper',
      () async {
        final listener = NotifyListener();
        viewModel.addListener(listener.call);

        final expectedTempFileIdent = await simulatePickImageWithHelper(
          viewModel,
          source: ImageSourceType.gallery,
        );
        expect(viewModel.isPickingImage, isFalse);
        expect(viewModel.currentImages.length, 1);
        expect(viewModel.currentImages[0], isA<TempFileIdentifier>());
        final addedImage = viewModel.currentImages[0] as TempFileIdentifier;
        expect(addedImage.file.path, expectedTempFileIdent.file.path);
        verify(listener.call()).called(2);
        viewModel.removeListener(listener.call);
      },
    );

    test(
      '_pickImageWithHelper does nothing if helper returns null (user cancelled)',
      () async {
        when(
          mockImagePickerService.pickImageFromCamera(),
        ).thenAnswer((_) async => null);

        await viewModel.pickImageFromCamera();

        expect(viewModel.isPickingImage, isFalse);
        expect(viewModel.currentImages.isEmpty, isTrue);
      },
    );

    test(
      '_pickImageWithHelper logs warning if tempDir is null and directSave is false',
      () async {
        when(
          mockTempFileService.createSessionTempDir(any),
        ).thenThrow(Exception('Failed to create temp directory'));
        final freshViewModel = createViewModel(
          imageDataService: mockImageDataService,
        );
        await Future.delayed(Duration.zero);

        await freshViewModel.pickImageFromCamera();
        expect(freshViewModel.isPickingImage, isFalse);
        expect(freshViewModel.currentImages.isEmpty, isTrue);
        expect(freshViewModel.currentImages.isEmpty, isTrue);
        expect(
          loggerManager.findLogWithMessage(
            'Temporary directory not initialized. Cannot pick image for non-direct save.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
        freshViewModel.dispose();
      },
    );

    test('_pickImageWithHelper handles and logs exception from helper', () async {
      when(
        mockImagePickerService.pickImageFromCamera(),
      ).thenThrow(Exception('Picker crashed'));

      await viewModel.pickImageFromCamera();

      expect(viewModel.isPickingImage, isFalse);
      expect(viewModel.currentImages.isEmpty, isTrue);
      expect(
        loggerManager.findLogWithMessage(
          'Helper: Error during pickImage: Exception: Picker crashed',
          level: Level.SEVERE,
        ),
        isNotNull,
        reason:
            'Should log a SEVERE error when image picking itself throws an exception.',
      );
    });

    test('does nothing if already picking image', () async {
      final imageCompleter = Completer<File?>();
      when(mockImagePickerService.pickImageFromCamera()).thenAnswer((
        invocation,
      ) {
        return imageCompleter.future;
      });

      final call1Future = viewModel.pickImageFromCamera();
      final call2Future = viewModel.pickImageFromCamera();

      final mockPickedFile = MockFile();
      when(mockPickedFile.path).thenReturn('path1');
      final mockCopiedFile = MockFile();
      when(mockCopiedFile.path).thenReturn('${mockTempDir.path}/path1_copied');
      when(
        mockTempFileService.copyToTempDir(mockPickedFile, mockTempDir),
      ).thenAnswer((_) async => mockCopiedFile);
      imageCompleter.complete(mockPickedFile);

      await call1Future;
      await call2Future;

      verify(mockImagePickerService.pickImageFromCamera()).called(1);
      expect(viewModel.currentImages.length, 1);
    });
  });

  group('removeImage', () {
    late EditLocationViewModel localVm;

    setUp(() async {
      localVm = createViewModel(imageDataService: mockImageDataService);
      await Future.delayed(Duration.zero);
      await simulatePickImageWithHelper(localVm); // Adds one TempFileIdentifier
      clearInteractions(mockImagePickerService);
      clearInteractions(mockTempFileService);
      when(
        mockTempFileService.createSessionTempDir(any),
      ).thenAnswer((_) async => mockTempDir);
    });

    tearDown(() {
      localVm.dispose();
    });

    test('removes TempFileIdentifier and deletes file', () async {
      expect(localVm.currentImages.length, 1);
      final tempFileToRemove =
          (localVm.currentImages[0] as TempFileIdentifier).file;
      final listener = NotifyListener();
      localVm.addListener(listener.call);

      await localVm.removeImage(0);

      expect(localVm.currentImages.isEmpty, isTrue);
      verify(mockTempFileService.deleteFile(tempFileToRemove)).called(1);
      verify(listener.call()).called(1);
      localVm.removeListener(listener.call);
    });

    test('removes GuidIdentifier', () async {
      final vmWithGuid = createViewModel(
        imageDataService: mockImageDataService,
        initialLoc: Location(
          id: 'loc-guid',
          name: 'Test',
          imageGuids: ['guid-to-remove'],
        ),
      );
      await Future.delayed(Duration.zero);
      expect(vmWithGuid.currentImages.length, 1);
      expect(vmWithGuid.currentImages[0], isA<GuidIdentifier>());

      final listener = NotifyListener();
      vmWithGuid.addListener(listener.call);
      await vmWithGuid.removeImage(0);

      expect(vmWithGuid.currentImages.isEmpty, isTrue);
      verifyNever(mockTempFileService.deleteFile(any));
      verify(listener()).called(1);
      expect(
        loggerManager.findLogWithMessage(
          "Image with GUID guid-to-remove marked for removal",
          level: Level.INFO,
        ),
        isNotNull,
      );
      vmWithGuid.removeListener(listener.call);
    });

    test(
      'handles error during temp file deletion when removing TempFileIdentifier',
      () async {
        expect(localVm.currentImages.length, 1);
        final tempFileCausingError =
            (localVm.currentImages[0] as TempFileIdentifier).file;
        when(
          mockTempFileService.deleteFile(tempFileCausingError),
        ).thenThrow(Exception('delete failed'));

        await localVm.removeImage(0);

        expect(
          localVm.currentImages.isEmpty,
          isTrue,
        ); // Still removed from list
        expect(
          loggerManager.findLogWithMessage(
            'Failed to delete temporary image file',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test('does nothing for invalid index', () async {
      final initialCount = localVm.currentImages.length;
      await localVm.removeImage(-1);
      await localVm.removeImage(initialCount);
      expect(localVm.currentImages.length, initialCount);
    });
  });

  group('saveLocation', () {
    setUp(() async {
      when(mockDataService.addLocation(any)).thenAnswer((_) async {});
      when(mockDataService.updateLocation(any)).thenAnswer((_) async {});
      when(
        mockTempFileService.deleteDirectory(mockTempDir),
      ).thenAnswer((_) async {});

      when(mockImageDataService.saveUserImage(any)).thenAnswer((
        invocation,
      ) async {
        final file = invocation.positionalArguments.first as File;
        return 'guid_for_${file.path.split('/').last.replaceAll('.', '_')}';
      });
      when(mockImageDataService.deleteUserImage(any)).thenAnswer((_) async {});
    });

    test('returns false if form validation fails', () async {
      viewModel = createViewModel(formShouldValidate: false);
      await Future.delayed(Duration.zero);
      viewModel.nameController.text = "Test";

      final result = await viewModel.saveLocation();

      expect(result, isFalse);
      expect(viewModel.isSaving, isFalse);
      verifyNever(mockDataService.addLocation(any));
    });

    test('returns false if already saving', () async {
      viewModel = createViewModel(
        imageDataService: mockImageDataService,
        formShouldValidate: true,
      );
      await Future.delayed(Duration.zero);
      viewModel.nameController.text = "Test Location";

      final saveCompleter = Completer<void>();
      when(
        mockDataService.addLocation(any),
      ).thenAnswer((_) => saveCompleter.future);

      final firstSaveFuture = viewModel.saveLocation();
      await Future.delayed(Duration.zero);
      expect(viewModel.isSaving, isTrue);

      final resultOfSecondCall = await viewModel.saveLocation();
      expect(resultOfSecondCall, isFalse);

      saveCompleter.complete();
      await firstSaveFuture;

      verify(mockDataService.addLocation(any)).called(1);
      expect(viewModel.isSaving, isFalse);
    });

    test('successfully saves a new location with no images', () async {
      viewModel = createViewModel(formShouldValidate: true);
      await Future.delayed(Duration.zero);
      viewModel.nameController.text = "New Location";

      final listener = NotifyListener();
      viewModel.addListener(listener.call);

      final result = await viewModel.saveLocation();

      expect(result, isTrue);
      expect(viewModel.isSaving, isFalse);
      verify(mockDataService.addLocation(any)).called(1);
      verifyNever(mockImageDataService.saveUserImage(any));
      verifyNever(mockImageDataService.deleteUserImage(any));
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);
      verify(listener()).called(greaterThan(0)); // for isSaving changes
      expect(
        loggerManager.findLogWithMessage(
          'New location added successfully',
          level: Level.INFO,
        ),
        isNotNull,
      );
      viewModel.removeListener(listener.call);
    });

    test(
      'successfully saves a new location with new images (ImageDataService available)',
      () async {
        viewModel = createViewModel(
          imageDataService: mockImageDataService,
          nameControllerText: "New Location With Image",
          formShouldValidate: true,
        );

        await Future.delayed(Duration.zero);

        final addedTempImageIdentifier = await simulatePickImageWithHelper(
          viewModel,
          tempCopiedImageName: 'new_image_to_save.jpg',
        );
        final tempFileToSave = addedTempImageIdentifier.file;
        final expectedGuid = 'guid_for_new_image_to_save_jpg';

        final result = await viewModel.saveLocation();

        expect(result, isTrue);
        verify(mockImageDataService.saveUserImage(tempFileToSave)).called(1);
        verify(
          mockDataService.addLocation(
            argThat(
              predicate<Location>(
                (loc) =>
                    loc.name == "New Location With Image" &&
                    loc.imageGuids != null &&
                    loc.imageGuids!.contains(expectedGuid),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'successfully updates an existing location, removing an old image, adding new',
      () async {
        initialLocation = Location(
          id: 'loc1',
          name: 'Old Name',
          imageGuids: ['old_guid_to_remove', 'guid_to_keep'],
        );
        viewModel = createViewModel(
          imageDataService: mockImageDataService,
          initialLoc: initialLocation,
          formShouldValidate: true,
          nameControllerText: "Updated Name",
        );
        await Future.delayed(Duration.zero);

        int indexOfOldGuid = viewModel.currentImages.indexWhere(
          (img) => img is GuidIdentifier && img.guid == 'old_guid_to_remove',
        );
        await viewModel.removeImage(indexOfOldGuid);

        final addedTempImageIdentifier = await simulatePickImageWithHelper(
          viewModel,
          tempCopiedImageName: 'new_temp_for_update.jpg',
        );
        final newTempFile = addedTempImageIdentifier.file;
        final expectedNewGuid = 'guid_for_new_temp_for_update_jpg';

        final result = await viewModel.saveLocation();
        expect(result, isTrue);

        verify(
          mockDataService.updateLocation(
            argThat(
              predicate<Location>(
                (loc) =>
                    loc.id == 'loc1' &&
                    loc.name == "Updated Name" &&
                    loc.imageGuids!.contains('guid_to_keep') &&
                    loc.imageGuids!.contains(expectedNewGuid) &&
                    !loc.imageGuids!.contains('old_guid_to_remove'),
              ),
            ),
          ),
        ).called(1);
        verify(mockImageDataService.saveUserImage(newTempFile)).called(1);
        verify(
          mockImageDataService.deleteUserImage('old_guid_to_remove'),
        ).called(1);
      },
    );

    test(
      'saveLocation fails if ImageDataService is null and new images are present',
      () async {
        viewModel = createViewModel(
          imageDataService: null, // Service is null
          formShouldValidate: true,
          nameControllerText: "Location Name",
        );
        await Future.delayed(Duration.zero);

        final addedTempImageIdentifier = await simulatePickImageWithHelper(
          viewModel,
        );
        final tempFileThatShouldBeCleanedUp = addedTempImageIdentifier.file;

        final result = await viewModel.saveLocation();

        expect(result, isFalse);
        verifyNever(mockDataService.addLocation(any));
        verify(
          mockTempFileService.deleteFile(tempFileThatShouldBeCleanedUp),
        ).called(1);
        verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);
      },
    );

    test(
      'saveLocation proceeds if ImageDataService is null and only existing/no images',
      () async {
        initialLocation = Location(
          id: 'loc1',
          name: 'Old Name',
          imageGuids: ['guid_to_keep'],
        );
        viewModel = createViewModel(
          imageDataService: null,
          initialLoc: initialLocation,
          formShouldValidate: true,
          nameControllerText: "Updated Name",
        );
        await Future.delayed(Duration.zero);

        final result = await viewModel.saveLocation();

        expect(result, isTrue);
        verify(
          mockDataService.updateLocation(
            argThat(
              predicate<Location>(
                (loc) =>
                    loc.id == 'loc1' &&
                    loc.name == "Updated Name" &&
                    loc.imageGuids!.length == 1 &&
                    loc.imageGuids!.contains('guid_to_keep'),
              ),
            ),
          ),
        ).called(1);
        verifyNever(mockImageDataService.saveUserImage(any));
        verifyNever(mockImageDataService.deleteUserImage(any));
        expect(
          loggerManager.findLogWithMessage(
            'IImageDataService is null. Proceeding without image saving/deletion capabilities.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'handles error during _processImagesForSave (image save fails)',
      () async {
        viewModel = createViewModel(
          imageDataService: mockImageDataService,
          formShouldValidate: true,
        );
        await Future.delayed(Duration.zero);

        final addedTempImageIdentifier = await simulatePickImageWithHelper(
          viewModel,
        );
        final tempFileToSave = addedTempImageIdentifier.file;

        when(
          mockImageDataService.saveUserImage(tempFileToSave),
        ).thenThrow(Exception('Failed to save image file'));

        final result = await viewModel.saveLocation();

        expect(result, isFalse);
        expect(viewModel.isSaving, isFalse);
        verifyNever(mockDataService.addLocation(any));
        verify(
          mockTempFileService.deleteDirectory(mockTempDir),
        ).called(1); // Cleanup still runs
      },
    );

    test('handles error during _saveLocationData (DB add fails)', () async {
      viewModel = createViewModel(
        formShouldValidate: true,
        nameControllerText: "DB Fail Location",
      );
      await Future.delayed(Duration.zero);

      when(mockDataService.addLocation(any)).thenThrow(Exception('DB error'));

      final result = await viewModel.saveLocation();

      expect(result, isFalse);
      expect(viewModel.isSaving, isFalse);
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);

      expect(
        loggerManager.findLogWithMessage(
          'Error saving location or processing images',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
      expect(
        loggerManager.findLogWithMessage('DB error', level: Level.SEVERE),
        isNotNull,
      );
    });

    test('handles error during _saveLocationData (DB update fails)', () async {
      initialLocation = Location(id: 'loc1', name: 'Old Name');
      viewModel = createViewModel(
        initialLoc: initialLocation,
        formShouldValidate: true,
        nameControllerText: "Updated Name for DB Fail",
      );
      await Future.delayed(Duration.zero);

      when(
        mockDataService.updateLocation(any),
      ).thenThrow(Exception('DB update error'));

      final result = await viewModel.saveLocation();

      expect(result, isFalse);
      expect(viewModel.isSaving, isFalse);
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);

      expect(
        loggerManager.findLogWithMessage(
          'Error saving location or processing images',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
      expect(
        loggerManager.findLogWithMessage(
          'DB update error',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
    });
  });

  group('Cleanup and Dispose', () {
    late MockBuildContext mockContext;
    late MockNavigatorState mockNavigatorState;

    setUp(() {
      mockContext = MockBuildContext();
      mockNavigatorState = MockNavigatorState();

      when(
        mockContext.findAncestorStateOfType<NavigatorState>(),
      ).thenReturn(mockNavigatorState);
      when(mockContext.mounted).thenReturn(true);
      when(mockNavigatorState.canPop()).thenReturn(true);

      when(mockNavigatorState.pop(any)).thenAnswer((_) async {});
    });

    test('handleDiscardOrPop calls _cleanupTempDir', () async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      await viewModel.handleDiscardOrPop(mockContext);
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);
      expect(
        loggerManager.findLogWithMessage(
          'Cleaned up temporary image directory',
          level: Level.INFO,
        ),
        isNotNull,
      );
    });

    test('_cleanupTempDir does nothing if _tempDir is null', () async {
      when(
        mockTempFileService.createSessionTempDir(any),
      ).thenThrow(Exception('Simulated failure'));
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      await viewModel.handleDiscardOrPop(
        mockContext,
      ); // Should internally check if _tempDir is null
      verifyNever(mockTempFileService.deleteDirectory(any));
    });

    test('_cleanupTempDir handles error during directory deletion', () async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);
      when(
        mockTempFileService.deleteDirectory(mockTempDir),
      ).thenThrow(Exception('delete dir failed'));

      await viewModel.handleDiscardOrPop(mockContext);
      expect(
        loggerManager.findLogWithMessage(
          'Failed to clean up temporary image directory',
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('dispose calls _cleanupTempDir if not already cleaned', () async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      viewModel.dispose();
      await pumpEventQueue(); // Allow async operations in dispose to complete

      await pumpEventQueue();

      // Verify _cleanupTempDir's core action was attempted because _tempDir was not null
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);
      expect(
        loggerManager.findLogWithMessage(
          "ViewModel disposed, but temp directory was not cleaned up",
          level: Level.WARNING,
        ),
        isNotNull,
      );
    });

    test('dispose does not try to cleanup tempDir if already null', () async {
      viewModel = createViewModel();
      await Future.delayed(Duration.zero);

      await viewModel.handleDiscardOrPop(
        mockContext,
      ); // Cleans up and sets _tempDir to null
      verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);

      clearInteractions(mockTempFileService); // Clear before calling dispose
      when(
            mockTempFileService.createSessionTempDir(any),
          ) // Re-stub if necessary
          .thenAnswer((_) async => mockTempDir);

      viewModel.dispose();
      await pumpEventQueue();

      verifyNever(
        mockTempFileService.deleteDirectory(any),
      ); // Should not be called again by dispose
      expect(
        loggerManager.findLogWithMessage(
          "ViewModel disposed, but temp directory was not cleaned up",
          level: Level.WARNING,
        ),
        isNull,
      ); // Log shouldn't appear
    });

    test(
      'dispose sets _isDisposed and can be called multiple times safely',
      () async {
        viewModel = createViewModel();
        await Future.delayed(Duration.zero);

        expect(viewModel.isDisposed, isFalse);
        viewModel.dispose();
        await pumpEventQueue();
        expect(viewModel.isDisposed, isTrue);

        viewModel.dispose(); // Call again
        await pumpEventQueue();
        // TODO: Ensure cleanup (like deleteDirectory) is only called once if it was pending
        verify(mockTempFileService.deleteDirectory(mockTempDir)).called(1);
      },
    );
  });
}
