import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:stuff/services/impl/geolocator_location_service.dart';
import 'package:stuff/services/wrappers/geolocator_wrapper.dart';
import 'package:stuff/services/wrappers/geocoding_wrapper.dart';
import 'package:stuff/services/permission_service_interface.dart';

// Import the generated mocks file.
import 'geolocator_location_service_test.mocks.dart';

// --- Test Logger Helper (remains the same) ---
List<LogRecord> _capturedLogs = [];
StreamSubscription<LogRecord>? _logSubscription;

void _startCapturingLogs() {
  _capturedLogs.clear();
  _logSubscription = Logger.root.onRecord.listen((LogRecord rec) {
    if (rec.loggerName == 'GeolocatorLocationService') {
      _capturedLogs.add(rec);
    }
  });
}

void _stopCapturingLogs() {
  _logSubscription?.cancel();
  _logSubscription = null;
}

LogRecord? _findLogWithMessage(String messagePart, {Level? level}) {
  return _capturedLogs.cast<LogRecord?>().firstWhere(
    (log) =>
        log!.message.contains(messagePart) &&
        (level == null || log.level == level),
    orElse: () => null,
  );
}
// --- End Test Logger Helper ---

@GenerateMocks([
  IGeolocatorWrapper,
  IGeocodingWrapper,
  IPermissionService,
  Placemark,
  Position,
])
void main() {
  late GeolocatorLocationService service;
  late MockIGeolocatorWrapper
  mockGeolocatorWrapper; // Use generated mock for the interface
  late MockIGeocodingWrapper
  mockGeocodingWrapper; // Use generated mock for the interface
  late MockPosition mockPosition;
  late MockPlacemark mockPlacemark;
  late MockIPermissionService mockPermissionService;

  setUpAll(() {
    Logger.root.level = Level.ALL;
  });

  setUp(() {
    mockGeolocatorWrapper = MockIGeolocatorWrapper();
    mockGeocodingWrapper = MockIGeocodingWrapper();
    mockPosition = MockPosition();
    mockPlacemark = MockPlacemark();
    mockPermissionService = MockIPermissionService();

    // Inject the mocks into the service
    service = GeolocatorLocationService(
      geolocator: mockGeolocatorWrapper,
      geocoding: mockGeocodingWrapper,
      permissionService: mockPermissionService,
    );
    _startCapturingLogs();
  });

  tearDown(() {
    _stopCapturingLogs();
  });

  group('isServiceEnabledAndPermitted', () {
    test(
      'should return false and log if location services are disabled',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        // ACT
        final result = await service.isServiceEnabledAndPermitted();

        // ASSERT
        expect(result, isFalse);
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verifyNever(
          mockPermissionService.checkLocationPermission(),
        ); // Should not check permission if service disabled
        await Future.delayed(Duration.zero); // Allow logs to process
        expect(
          _findLogWithMessage(
            "Location services are disabled.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return false and log if permission is deniedForever',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        // ACT
        final result = await service.isServiceEnabledAndPermitted();

        // ASSERT
        expect(result, isFalse);
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verify(mockPermissionService.checkLocationPermission()).called(1);
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "Location permission permanently denied.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test('should return false and log if permission is denied', () async {
      // ARRANGE
      when(
        mockGeolocatorWrapper.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.checkLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      // ACT
      final result = await service.isServiceEnabledAndPermitted();

      // ASSERT
      expect(result, isFalse);
      await Future.delayed(Duration.zero);
      expect(
        _findLogWithMessage(
          "Location permission denied (but not permanently).",
          level: Level.INFO,
        ),
        isNotNull,
      );
    });

    test(
      'should return true and log if service enabled and permission granted (e.g., whileInUse)',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);

        // ACT
        final result = await service.isServiceEnabledAndPermitted();

        // ASSERT
        expect(result, isTrue);
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "Location services enabled and permission granted.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return true and log if service enabled and permission granted (e.g., always)',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.always);

        // ACT
        final result = await service.isServiceEnabledAndPermitted();

        // ASSERT
        expect(result, isTrue);
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "Location services enabled and permission granted.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );
  });

  group('getCurrentPosition', () {
    test(
      'should return position if service enabled and permission granted',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorWrapper.getCurrentPosition(),
        ).thenAnswer((_) async => mockPosition);

        // ACT
        final result = await service.getCurrentPosition();

        // ASSERT
        expect(result, mockPosition);
        verify(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).called(1); // from isServiceEnabledAndPermitted
        verify(
          mockPermissionService.checkLocationPermission(),
        ).called(1); // from isServiceEnabledAndPermitted
        verifyNever(
          mockPermissionService.requestLocationPermission(),
        ); // Should not request if already permitted
        verify(mockGeolocatorWrapper.getCurrentPosition()).called(1);
      },
    );

    test(
      'should request permission and return position if initially denied but then granted',
      () async {
        // ARRANGE
        // For isServiceEnabledAndPermitted initially:
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        when(mockPermissionService.requestLocationPermission()).thenAnswer(
          (_) async => LocationPermission.whileInUse,
        ); // Granted after request
        when(
          mockGeolocatorWrapper.getCurrentPosition(),
        ).thenAnswer((_) async => mockPosition);

        // ACT
        final result = await service.getCurrentPosition();

        // ASSERT
        expect(result, mockPosition);
        // isServiceEnabledAndPermitted calls:
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        // checkPermission is called twice: once by isServiceEnabledAndPermitted, once by getCurrentPosition
        verify(mockPermissionService.checkLocationPermission()).called(2);
        verify(mockPermissionService.requestLocationPermission()).called(1);
        verify(mockGeolocatorWrapper.getCurrentPosition()).called(1);
        await Future.delayed(Duration.zero);
      },
    );

    test(
      'should throw exception if permission denied after request and log warning',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        // Simulate isServiceEnabledAndPermitted returning false due to initial denial
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        when(
          mockPermissionService.requestLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied); // Still denied

        // ACT & ASSERT
        await expectLater(
          service.getCurrentPosition(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('Location permission not granted'),
            ),
          ),
        );
        verify(mockPermissionService.requestLocationPermission()).called(1);
        verifyNever(mockGeolocatorWrapper.getCurrentPosition());
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "Attempted to get position without sufficient permission.",
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should throw exception if permission deniedForever after request and log warning',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        when(mockPermissionService.requestLocationPermission()).thenAnswer(
          (_) async => LocationPermission.deniedForever,
        ); // Denied forever

        // ACT & ASSERT
        await expectLater(
          service.getCurrentPosition(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains('Location permission not granted'),
            ),
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "Attempted to get position without sufficient permission.",
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should rethrow exception from geolocatorWrapper.getCurrentPosition and log severe',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.always);
        final exception = Exception('Geolocator Platform Error');
        when(mockGeolocatorWrapper.getCurrentPosition()).thenThrow(exception);

        // ACT & ASSERT
        await expectLater(service.getCurrentPosition(), throwsA(exception));
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            'Error getting current position: $exception',
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );
  });

  group('getCurrentAddress', () {
    final testLatitude = 34.0522;
    final testLongitude = -118.2437;

    setUp(() {
      when(mockPosition.latitude).thenReturn(testLatitude);
      when(mockPosition.longitude).thenReturn(testLongitude);
    });

    test('should return null and log if getCurrentPosition returns null', () async {
      // ARRANGE

      // Let's assume getCurrentPosition throws a permission exception
      final permissionExceptionMessage =
          'Location permission not granted or service disabled.';
      when(
        mockGeolocatorWrapper.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.checkLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      when(
        mockPermissionService.requestLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.denied); // Still denied

      // ACT & ASSERT

      expectLater(
        service.getCurrentAddress(), // Future is passed directly
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains(permissionExceptionMessage),
          ),
        ),
      );

      await pumpEventQueue();

      // ASSERT LOGS
      // Log from getCurrentPosition (source of the exception)
      expect(
        _findLogWithMessage(
          "Attempted to get position without sufficient permission.",
          level: Level.WARNING,
        ),
        isNotNull,
        reason:
            "Log from getCurrentPosition for permission denial was not found.",
      );

      // Log from getCurrentAddress (which catches and rethrows)
      expect(
        _findLogWithMessage(
          "Error getting current address: Exception: $permissionExceptionMessage",
          level: Level.SEVERE,
        ),
        isNotNull,
        reason:
            "Log from getCurrentAddress for rethrown exception was not found.",
      );
    });

    test(
      'should return null and log if geocoding returns no placemarks',
      () async {
        // ARRANGE
        // Make getCurrentPosition succeed
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorWrapper.getCurrentPosition(),
        ).thenAnswer((_) async => mockPosition);

        // Make geocoding return empty list
        when(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).thenAnswer((_) async => []);

        // ACT
        final result = await service.getCurrentAddress();

        // ASSERT
        expect(result, isNull);
        verify(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).called(1);
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            "No placemarks found for the current location.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return formatted address if geocoding returns placemarks',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorWrapper.getCurrentPosition(),
        ).thenAnswer((_) async => mockPosition);

        when(mockPlacemark.street).thenReturn('123 Main St');
        when(mockPlacemark.subLocality).thenReturn('Downtown');
        when(mockPlacemark.locality).thenReturn('Anytown');
        when(mockPlacemark.postalCode).thenReturn('90210');
        when(mockPlacemark.country).thenReturn('USA');
        // Ensure all fields accessed are stubbed, even if to empty string
        when(
          mockPlacemark.administrativeArea,
        ).thenReturn(''); // Example of another field

        when(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).thenAnswer(
          (_) async => [mockPlacemark],
        ); // Return a list with the mock placemark

        // ACT
        final result = await service.getCurrentAddress();

        // ASSERT
        expect(result, '123 Main St, Downtown, Anytown, 90210, USA');
        verify(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).called(1);
      },
    );

    test(
      'should return null and log for geocoding non-permission errors',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorWrapper.getCurrentPosition(),
        ).thenAnswer((_) async => mockPosition);

        final geocodingException = Exception('Geocoding Service Not Available');
        when(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).thenThrow(geocodingException);

        // ACT
        final result = await service.getCurrentAddress();

        // ASSERT
        expect(
          result,
          isNull,
        ); // Service's catch-all returns null for non-permission exceptions from geocoding
        await Future.delayed(Duration.zero);
        expect(
          _findLogWithMessage(
            'Error getting current address: $geocodingException',
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );

    test('should rethrow permission exception from getCurrentPosition', () async {
      // ARRANGE
      final permissionExceptionMessage =
          'Location permission not granted or service disabled.';
      final expectedException = isA<Exception>().having(
        (e) => e.toString(),
        'toString',
        contains(permissionExceptionMessage),
      );
      when(
        mockGeolocatorWrapper.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.checkLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);

      when(
        mockPermissionService.requestLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);

      // ACT & ASSERT
      expectLater(service.getCurrentAddress(), throwsA(expectedException));

      await pumpEventQueue();

      // The SEVERE log will be for the rethrown exception from getCurrentAddress
      expect(
        _findLogWithMessage(
          'Error getting current address: Exception: $permissionExceptionMessage',
          level: Level.SEVERE,
        ),
        isNotNull,
        reason:
            "SEVERE log from getCurrentAddress was not found or message incorrect.",
      );

      // The WARNING log from getCurrentPosition will also occur
      expect(
        _findLogWithMessage(
          "Attempted to get position without sufficient permission.",
          level: Level.WARNING,
        ),
        isNotNull,
        reason: "WARNING log from getCurrentPosition was not found.",
      );
    });
  });
}
