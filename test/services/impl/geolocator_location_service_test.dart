import 'dart:async';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';
import 'package:geocoding/geocoding.dart' as geocoding_platform;
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/services/impl/geolocator_location_service.dart';
import 'package:stuff/services/wrappers/geolocator_wrapper.dart';
import 'package:stuff/services/wrappers/geocoding_wrapper.dart';
import 'package:stuff/services/permission_service_interface.dart';
import 'package:stuff/services/exceptions/permission_exceptions.dart';
import 'package:stuff/services/exceptions/os_service_exceptions.dart';
import '../../utils/test_logger_manager.dart';

// Import the generated mocks file.
import 'geolocator_location_service_test.mocks.dart';

@GenerateMocks([
  IGeolocatorWrapper,
  IGeocodingWrapper,
  IPermissionService,
  geocoding_platform.Placemark,
  Position,
])
void main() {
  late GeolocatorLocationService service;
  late MockIGeolocatorWrapper mockGeolocatorWrapper;
  late MockIGeocodingWrapper mockGeocodingWrapper;
  late MockPosition mockPosition;
  late MockPlacemark mockPlacemark;
  late MockIPermissionService mockPermissionService;
  late TestLoggerManager loggerManager;

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
    loggerManager = TestLoggerManager();
    loggerManager.startCapture();
  });

  tearDown(() {
    loggerManager.stopCapture();
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
          loggerManager.findLogWithMessage(
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
          loggerManager.findLogWithMessage(
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
        loggerManager.findLogWithMessage(
          "Location permission denied (but not permanently).",
          level: Level.INFO,
        ),
        isNotNull,
      );
    });

    test(
      'should return true and log if service enabled and permission granted (whileInUse)',
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
          loggerManager.findLogWithMessage(
            "Location services enabled and permission granted.",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return true and log if service enabled and permission granted (always)',
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
          loggerManager.findLogWithMessage(
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
      'should throw OSServiceDisabledException if location services are disabled',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => false);

        // ACT & ASSERT
        expect(
          () => service.getCurrentPosition(),
          throwsA(
            isA<OSServiceDisabledException>().having(
              (e) => e.serviceName,
              'serviceName',
              'Location',
            ),
          ),
        ); // Check serviceName
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verifyNever(mockPermissionService.checkLocationPermission());
        verifyNever(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Location services are disabled on the device.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return position if service enabled and permission granted (whileInUse)',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.whileInUse);
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => mockPosition);

        // ACT
        final result = await service.getCurrentPosition();

        // ASSERT
        expect(result, mockPosition);
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verify(mockPermissionService.checkLocationPermission()).called(1);
        verifyNever(mockPermissionService.requestLocationPermission());
        verify(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).called(1);
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Attempting to get current position with accuracy',
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return position if service enabled and permission granted (always)',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.always);
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => mockPosition);

        // ACT
        final result = await service.getCurrentPosition();

        // ASSERT
        expect(result, mockPosition);
        // Verifications are similar to whileInUse
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verify(mockPermissionService.checkLocationPermission()).called(1);
        verifyNever(mockPermissionService.requestLocationPermission());
        verify(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).called(1);
      },
    );

    test(
      'should request permission and return position if initially denied but then granted whileInUse',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(mockPermissionService.checkLocationPermission()).thenAnswer(
          (_) async => LocationPermission.denied,
        ); // Initially denied
        when(mockPermissionService.requestLocationPermission()).thenAnswer(
          (_) async => LocationPermission.whileInUse,
        ); // Granted after request
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) async => mockPosition);

        // ACT
        final result = await service.getCurrentPosition();

        // ASSERT
        expect(result, mockPosition);
        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verify(mockPermissionService.checkLocationPermission()).called(1);
        verify(mockPermissionService.requestLocationPermission()).called(1);
        verify(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).called(1);
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Location permission is denied, requesting permission...',
            level: Level.INFO,
          ),
          isNotNull,
        );
        expect(
          loggerManager.findLogWithMessage(
            'Permission status after request: LocationPermission.whileInUse',
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should throw LocationPermissionDeniedException if permission denied after request',
      () async {
        // ARRANGE
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

        expect(
          () => service.getCurrentPosition(),
          throwsA(isA<LocationPermissionDeniedException>()),
        );

        await pumpEventQueue();

        verify(mockPermissionService.requestLocationPermission()).called(1);
        verifyNever(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        );
        expect(
          loggerManager.findLogWithMessage(
            'Location permission was denied by the user after request.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    // CHANGED: Test for LocationPermissionDeniedPermanentlyException (from initial check)
    test(
      'should throw LocationPermissionDeniedPermanentlyException if permission is deniedForever initially',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        // ACT & ASSERT
        expect(
          () => service.getCurrentPosition(),
          throwsA(isA<LocationPermissionDeniedPermanentlyException>()),
        );
        await pumpEventQueue();

        verify(mockGeolocatorWrapper.isLocationServiceEnabled()).called(1);
        verify(mockPermissionService.checkLocationPermission()).called(1);
        verifyNever(mockPermissionService.requestLocationPermission());
        verifyNever(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        );

        expect(
          loggerManager.findLogWithMessage(
            'Location permissions are permanently denied.',
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
        final geolocatorException = Exception('Geolocator Platform Error');
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(geolocatorException);

        // ACT & ASSERT
        await expectLater(
          service.getCurrentPosition(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains(
                'An unexpected error occurred while fetching location: $geolocatorException',
              ),
            ),
          ),
        );
        await pumpEventQueue();

        expect(
          loggerManager.findLogWithMessage(
            'An unexpected error occurred in _geolocator.getCurrentPosition: $geolocatorException',
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should throw LocationPermissionDeniedPermanentlyException if permission deniedForever after request',
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
        ); // Denied forever after request

        // ACT & ASSERT
        expect(
          () => service.getCurrentPosition(),
          throwsA(isA<LocationPermissionDeniedPermanentlyException>()),
        );
        await pumpEventQueue();
        verify(mockPermissionService.requestLocationPermission()).called(1);
        verifyNever(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        );

        expect(
          loggerManager.findLogWithMessage(
            'Location permissions are permanently denied.', // This log is from the second check after request
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should throw TimeoutException if geolocator.getCurrentPosition times out via Future.timeout (using FakeAsync)',
      () {
        fakeAsync((FakeAsync fa) {
          // ARRANGE
          when(
            mockGeolocatorWrapper.isLocationServiceEnabled(),
          ).thenAnswer((_) async => true);
          when(
            mockPermissionService.checkLocationPermission(),
          ).thenAnswer((_) async => LocationPermission.whileInUse);

          final nonCompletingGeolocatorCall = Completer<Position>();
          when(
            mockGeolocatorWrapper.getCurrentPosition(
              locationSettings: anyNamed('locationSettings'),
            ),
          ).thenAnswer((_) => nonCompletingGeolocatorCall.future);

          // ACT
          bool caughtCorrectException = false;
          String? timeoutExceptionMessage;

          service.getCurrentPosition().then(
            (value) {
              /* Should not happen */
            },
            onError: (error) {
              if (error is TimeoutException) {
                caughtCorrectException = true;
                timeoutExceptionMessage = error.message;
              }
            },
          );

          fa.elapse(const Duration(seconds: 21));
          fa.flushMicrotasks();

          // ASSERT
          expect(
            caughtCorrectException,
            isTrue,
            reason: "TimeoutException was not caught by the future's onError.",
          );
          expect(
            timeoutExceptionMessage,
            contains('Getting location timed out.'),
          );

          expect(
            loggerManager.findLogWithMessage(
              'Timeout occurred while getting current position.',
              level: Level.WARNING,
            ),
            isNotNull,
            reason: "Log from onTimeout was not found.",
          );
          expect(
            loggerManager.findLogWithMessage(
              'Caught TimeoutException from .timeout() while getting current position.',
              level: Level.WARNING,
            ),
            isNotNull,
            reason: "Log from service's catch block was not found.",
          );
        });
      },
    );

    test(
      'should rethrow generic Exception from geolocatorWrapper.getCurrentPosition',
      () async {
        // ARRANGE
        when(
          mockGeolocatorWrapper.isLocationServiceEnabled(),
        ).thenAnswer((_) async => true);
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.always);
        final exception = Exception('Geolocator Platform Error');
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenThrow(exception);

        // ACT & ASSERT
        expect(
          () => service.getCurrentPosition(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'toString',
              contains(
                'An unexpected error occurred while fetching location: $exception',
              ),
            ),
          ),
        );
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'An unexpected error occurred in _geolocator.getCurrentPosition: $exception',
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );

    test('should throw Exception for unexpected permission state', () async {
      // ARRANGE
      when(
        mockGeolocatorWrapper.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);

      when(mockPermissionService.checkLocationPermission()).thenAnswer(
        (_) async => LocationPermission.unableToDetermine,
      ); // A state that might fall through

      // ACT & ASSERT
      expect(
        () => service.getCurrentPosition(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains(
              "Unexpected permission state: LocationPermission.unableToDetermine",
            ),
          ),
        ),
      );
      await pumpEventQueue();
      expect(
        loggerManager.findLogWithMessage(
          'Reached unexpected state in getCurrentPosition. Permission: LocationPermission.unableToDetermine',
          level: Level.SEVERE,
        ),
        isNotNull,
      );
    });
  });

  group('getCurrentAddress', () {
    final testLatitude = 34.0522;
    final testLongitude = -118.2437;

    setUp(() {
      // Stubbing latitude and longitude for mockPosition
      when(mockPosition.latitude).thenReturn(testLatitude);
      when(mockPosition.longitude).thenReturn(testLongitude);

      // WTH: might as well stub these as well!
      when(mockPosition.accuracy).thenReturn(0.0);
      when(mockPosition.altitude).thenReturn(0.0);
      when(mockPosition.heading).thenReturn(0.0);
      when(mockPosition.speed).thenReturn(0.0);
      when(mockPosition.speedAccuracy).thenReturn(0.0);
      when(mockPosition.timestamp).thenReturn(DateTime.now());
      when(mockPosition.altitudeAccuracy).thenReturn(0.0);
      when(mockPosition.headingAccuracy).thenReturn(0.0);

      // Default success for getCurrentPosition within this group, override in specific tests if needed
      when(
        mockGeolocatorWrapper.isLocationServiceEnabled(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.checkLocationPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      when(
        mockGeolocatorWrapper.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        ),
      ).thenAnswer((_) async => mockPosition);
    });

    test(
      'should rethrow OSServiceDisabledException from getCurrentPosition',
      () async {
        // ARRANGE
        // Override default setup for getCurrentPosition to make it throw
        when(mockGeolocatorWrapper.isLocationServiceEnabled()).thenAnswer(
          (_) async => false,
        ); // This will make getCurrentPosition throw

        // ACT & ASSERT
        expect(
          () => service.getCurrentAddress(),
          throwsA(isA<OSServiceDisabledException>()),
        );
        await Future.delayed(Duration.zero);
        // Log from getCurrentPosition
        expect(
          loggerManager.findLogWithMessage(
            'Location services are disabled on the device.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
        // Log from getCurrentAddress (rethrown)
        // The current getCurrentAddress rethrows without adding its own log message for these specific types
        // so we only expect the original log from getCurrentPosition.
      },
    );

    test(
      'should rethrow LocationPermissionDeniedException from getCurrentPosition',
      () async {
        // ARRANGE
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);
        when(
          mockPermissionService.requestLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.denied);

        // ACT & ASSERT
        expect(
          () => service.getCurrentAddress(),
          throwsA(isA<LocationPermissionDeniedException>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Location permission was denied by the user after request.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should rethrow LocationPermissionDeniedPermanentlyException from getCurrentPosition',
      () async {
        // ARRANGE
        when(
          mockPermissionService.checkLocationPermission(),
        ).thenAnswer((_) async => LocationPermission.deniedForever);

        // ACT & ASSERT
        expect(
          () => service.getCurrentAddress(),
          throwsA(isA<LocationPermissionDeniedPermanentlyException>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            'Location permissions are permanently denied.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      },
    );

    test('should rethrow TimeoutException from getCurrentPosition', () {
      fakeAsync((FakeAsync fa) {
        // ARRANGE
        when(
          mockGeolocatorWrapper.getCurrentPosition(
            locationSettings: anyNamed('locationSettings'),
          ),
        ).thenAnswer((_) => Completer<Position>().future); // Will cause timeout

        // ACT & ASSERT
        expect(
          () => service.getCurrentAddress(),
          throwsA(isA<TimeoutException>()),
        );

        fa.elapse(const Duration(seconds: 21)); // Trigger timeout
        fa.flushMicrotasks();

        expect(
          loggerManager.findLogWithMessage(
            'Timeout occurred while getting current position.',
            level: Level.WARNING,
          ),
          isNotNull,
        );
      });
    });

    test(
      'should return formatted address if geocoding returns placemarks',
      () async {
        // ARRANGE
        // getCurrentPosition succeeds (from group setUp)
        when(mockPlacemark.street).thenReturn('123 Main St');
        when(mockPlacemark.subLocality).thenReturn('Downtown');
        when(mockPlacemark.locality).thenReturn('Anytown');
        when(mockPlacemark.postalCode).thenReturn('90210');
        when(mockPlacemark.country).thenReturn('USA');
        // Stub other fields that might be accessed by the formatting logic to avoid null errors
        when(mockPlacemark.name).thenReturn('');
        when(mockPlacemark.isoCountryCode).thenReturn('');
        when(mockPlacemark.subAdministrativeArea).thenReturn('');
        when(mockPlacemark.administrativeArea).thenReturn('');
        when(mockPlacemark.thoroughfare).thenReturn('');
        when(mockPlacemark.subThoroughfare).thenReturn('');

        when(
          mockGeocodingWrapper.placemarkFromCoordinates(
            testLatitude,
            testLongitude,
          ),
        ).thenAnswer((_) async => [mockPlacemark]);

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
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            "Formatted address: $result",
            level: Level.INFO,
          ),
          isNotNull,
        );
      },
    );

    test(
      'should return null and log for geocoding non-permission errors',
      () async {
        // ARRANGE
        // getCurrentPosition succeeds (from group setUp)
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
        expect(result, isNull);
        await Future.delayed(Duration.zero);
        expect(
          loggerManager.findLogWithMessage(
            // CHANGED: Match the new log message format in getCurrentAddress for this case
            'Error during geocoding or other issue in getCurrentAddress: $geocodingException',
            level: Level.SEVERE,
          ),
          isNotNull,
        );
      },
    );
  });
}
