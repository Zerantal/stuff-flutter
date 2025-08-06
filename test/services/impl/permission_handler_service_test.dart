// test/services/impl/permission_handler_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

import 'package:stuff/services/impl/permission_handler_service.dart';

import '../../utils/test_logger_manager.dart';

class MockPermissionHandlerPlatform extends PermissionHandlerPlatform
    with Mock {
  MockPermissionHandlerPlatform();

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) {
    // This will be handled by the Mock mixin's noSuchMethod if not overridden here
    // for a specific default. For stubbing with `when`, this is fine.
    return super.noSuchMethod(
          Invocation.method(#checkPermissionStatus, [permission]),
          returnValue: Future.value(PermissionStatus.denied),
          returnValueForMissingStub: Future.value(PermissionStatus.denied),
        )
        as Future<PermissionStatus>;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) {
    return super.noSuchMethod(
          Invocation.method(#requestPermissions, [permissions]),
          returnValue: Future.value({
            for (var p in permissions) p: PermissionStatus.denied,
          }),
          returnValueForMissingStub: Future.value({
            for (var p in permissions) p: PermissionStatus.denied,
          }),
        )
        as Future<Map<Permission, PermissionStatus>>;
  }
}

class MockGeolocatorPlatform extends GeolocatorPlatform with Mock {
  MockGeolocatorPlatform();

  @override
  Future<LocationPermission> checkPermission() {
    return super.noSuchMethod(
          Invocation.method(#checkPermission, []),
          returnValue: Future.value(LocationPermission.denied),
          returnValueForMissingStub: Future.value(LocationPermission.denied),
        )
        as Future<LocationPermission>;
  }

  @override
  Future<LocationPermission> requestPermission() {
    return super.noSuchMethod(
          Invocation.method(#requestPermission, []),
          returnValue: Future.value(LocationPermission.denied),
          returnValueForMissingStub: Future.value(LocationPermission.denied),
        )
        as Future<LocationPermission>;
  }

  @override
  Future<bool> isLocationServiceEnabled() {
    return super.noSuchMethod(
          Invocation.method(#isLocationServiceEnabled, []),
          returnValue: Future.value(true),
          returnValueForMissingStub: Future.value(true),
        )
        as Future<bool>;
  }
}

void main() {
  late PermissionHandlerService service;
  late MockPermissionHandlerPlatform mockPermissionPlatform;
  late MockGeolocatorPlatform mockGeolocatorPlatform;
  late TestLoggerManager loggerManager;

  setUp(() {
    service = PermissionHandlerService();

    mockPermissionPlatform = MockPermissionHandlerPlatform();
    PermissionHandlerPlatform.instance = mockPermissionPlatform;

    mockGeolocatorPlatform = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocatorPlatform;

    loggerManager = TestLoggerManager();
    loggerManager.startCapture();
  });

  tearDown(() {
    loggerManager.stopCapture();
  });

  group('requestCameraPermission', () {
    test(
      'should return true if camera permission is already granted',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.granted);

        // ACT
        final result = await service.requestCameraPermission();

        // ASSERT
        expect(result, isTrue);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).called(1);
        verifyNever(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        );
      },
    );

    test(
      'should request and return true if permission initially denied then granted',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).thenAnswer(
          (_) async => {Permission.camera: PermissionStatus.granted},
        );

        // ACT
        final result = await service.requestCameraPermission();

        // ASSERT
        expect(result, isTrue);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).called(1);
      },
    );

    test(
      'should request and return false if permission initially denied and request also denied',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).thenAnswer((_) async => {Permission.camera: PermissionStatus.denied});

        // ACT
        final result = await service.requestCameraPermission();

        // ASSERT
        expect(result, isFalse);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).called(1);
      },
    );

    test(
      'should return false if permission is permanently denied and request does not change it',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
        // When status is permanentlyDenied, request() is still called by the service.
        // The OS dialog might not show, or show a disabled permission.
        // The returned status from request() in such a case is usually still permanentlyDenied.
        when(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).thenAnswer(
          (_) async => {Permission.camera: PermissionStatus.permanentlyDenied},
        );

        // ACT
        final result = await service.requestCameraPermission();

        // ASSERT
        expect(result, isFalse); // isGranted will be false
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.camera),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.camera]),
        ).called(1);
      },
    );
  });

  group('requestGalleryPermission', () {
    test(
      'should return true and log if gallery permission is already granted',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.granted);

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isTrue);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verifyNever(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        );
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.granted",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is sufficient (granted or limited). Proceeding.",
          ),
          isNotNull,
        );
      },
    );

    test('should return true and log if gallery permission is limited', () async {
      // ARRANGE
      when(
        mockPermissionPlatform.checkPermissionStatus(Permission.photos),
      ).thenAnswer((_) async => PermissionStatus.limited);

      // ACT
      final result = await service.requestGalleryPermission();

      // ASSERT
      expect(result, isTrue);
      verify(
        mockPermissionPlatform.checkPermissionStatus(Permission.photos),
      ).called(1);
      verifyNever(
        mockPermissionPlatform.requestPermissions([Permission.photos]),
      );
      expect(
        loggerManager.findLogWithMessage(
          "Initial gallery/photos status: PermissionStatus.limited",
        ),
        isNotNull,
      );
      expect(
        loggerManager.findLogWithMessage(
          "Gallery/photos permission is sufficient (granted or limited). Proceeding.",
        ),
        isNotNull,
      );
    });

    test(
      'should request, return true, and log if initially denied then granted',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).thenAnswer(
          (_) async => {Permission.photos: PermissionStatus.granted},
        );

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isTrue);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.denied",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is not sufficient (PermissionStatus.denied). Requesting...",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Status after gallery/photos request: PermissionStatus.granted",
          ),
          isNotNull,
        );
      },
    );

    test(
      'should request, return true, and log if initially denied then limited',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).thenAnswer(
          (_) async => {Permission.photos: PermissionStatus.limited},
        );

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isTrue);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.denied",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is not sufficient (PermissionStatus.denied). Requesting...",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Status after gallery/photos request: PermissionStatus.limited",
          ),
          isNotNull,
        );
      },
    );

    test(
      'should request, return false, and log if initially denied and request also denied',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.denied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).thenAnswer((_) async => {Permission.photos: PermissionStatus.denied});

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isFalse);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.denied",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is not sufficient (PermissionStatus.denied). Requesting...",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Status after gallery/photos request: PermissionStatus.denied",
          ),
          isNotNull,
        );
      },
    );

    test(
      'should request, return false, and log if status is permanentlyDenied',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.permanentlyDenied);
        when(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).thenAnswer(
          (_) async => {Permission.photos: PermissionStatus.permanentlyDenied},
        ); // Or .denied

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isFalse);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.permanentlyDenied",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is not sufficient (PermissionStatus.permanentlyDenied). Requesting...",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Status after gallery/photos request: PermissionStatus.permanentlyDenied",
          ),
          isNotNull,
        );
      },
    );

    test(
      'should request, return false, and log if status is restricted',
      () async {
        // ARRANGE
        when(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).thenAnswer((_) async => PermissionStatus.restricted);
        when(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).thenAnswer(
          (_) async => {Permission.photos: PermissionStatus.restricted},
        ); // Or .denied

        // ACT
        final result = await service.requestGalleryPermission();

        // ASSERT
        expect(result, isFalse);
        verify(
          mockPermissionPlatform.checkPermissionStatus(Permission.photos),
        ).called(1);
        verify(
          mockPermissionPlatform.requestPermissions([Permission.photos]),
        ).called(1);
        expect(
          loggerManager.findLogWithMessage(
            "Initial gallery/photos status: PermissionStatus.restricted",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Gallery/photos permission is not sufficient (PermissionStatus.restricted). Requesting...",
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            "Status after gallery/photos request: PermissionStatus.restricted",
          ),
          isNotNull,
        );
      },
    );
  });

  group('checkLocationPermission', () {
    test(
      'should return the result from GeolocatorPlatform.checkPermission',
      () async {
        // ARRANGE
        when(
          mockGeolocatorPlatform.checkPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        // ACT
        final result = await service.checkLocationPermission();

        // ASSERT
        expect(result, LocationPermission.whileInUse);
        verify(mockGeolocatorPlatform.checkPermission()).called(1);
      },
    );

    test('should correctly return LocationPermission.denied', () async {
      // ARRANGE
      when(
        mockGeolocatorPlatform.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      // ACT
      final result = await service.checkLocationPermission();
      // ASSERT
      expect(result, LocationPermission.denied);
    });
  });

  group('requestLocationPermission', () {
    test(
      'should return the result from GeolocatorPlatform.requestPermission',
      () async {
        // ARRANGE
        when(
          mockGeolocatorPlatform.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.always);

        // ACT
        final result = await service.requestLocationPermission();

        // ASSERT
        expect(result, LocationPermission.always);
        verify(mockGeolocatorPlatform.requestPermission()).called(1);
      },
    );

    test(
      'should correctly return LocationPermission.deniedForever from request',
      () async {
        // ARRANGE
        when(
          mockGeolocatorPlatform.requestPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);
        // ACT
        final result = await service.requestLocationPermission();
        // ASSERT
        expect(result, LocationPermission.deniedForever);
      },
    );
  });
}
