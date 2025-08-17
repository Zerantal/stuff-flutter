import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:stuff/services/contracts/data_service_interface.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/services/contracts/image_picker_service_interface.dart';
import 'package:stuff/services/contracts/location_service_interface.dart';
import 'package:stuff/services/contracts/temporary_file_service_interface.dart';

import 'mocks.dart';

class ProvidedMockServices {
  final MockIDataService dataService;
  final MockIImageDataService imageDataService;
  final MockILocationService locationService;
  final MockITemporaryFileService temporaryFileService;
  final MockIImagePickerService imagePickerService;

  ProvidedMockServices()
    : dataService = MockIDataService(),
      imageDataService = MockIImageDataService(),
      locationService = MockILocationService(),
      temporaryFileService = MockITemporaryFileService(),
      imagePickerService = MockIImagePickerService();

  List<SingleChildWidget> get providers => [
    Provider<IDataService>.value(value: dataService),
    Provider<IImageDataService>.value(value: imageDataService),
    Provider<ILocationService>.value(value: locationService),
    Provider<ITemporaryFileService>.value(value: temporaryFileService),
    Provider<IImagePickerService>.value(value: imagePickerService),
  ];
}

/// Pumps a widget tree with providers, optionally a router, and an optional
/// mock ViewModel of type T (ChangeNotifier).
Future<void> pumpPageWithProviders<T extends ChangeNotifier>(
  WidgetTester tester, {
  required Widget pageWidget,
  List<SingleChildWidget> providers = const [],
  T? mockViewModel,
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
}) async {
  final allProviders = List<SingleChildWidget>.from(providers);

  if (mockViewModel != null) {
    allProviders.insert(0, ChangeNotifierProvider<T>.value(value: mockViewModel));
  }

  final Widget app = router == null
      ? MaterialApp(
          home: MediaQuery(data: mediaQueryData ?? const MediaQueryData(), child: pageWidget),
          navigatorObservers: navigatorObservers,
        )
      : MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: mediaQueryData ?? const MediaQueryData(),
            child: child ?? const SizedBox.shrink(),
          ),
        );

  await tester.pumpWidget(MultiProvider(providers: allProviders, child: app));
}

/// Convenience: creates common mock services, injects them, returns the mocks.
Future<ProvidedMockServices> pumpPageWithServices<T extends ChangeNotifier>(
  WidgetTester tester, {
  required Widget pageWidget,
  T? mockViewModel,
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
  void Function(ProvidedMockServices m)? onMocksReady,
}) async {
  final mocks = ProvidedMockServices();
  onMocksReady?.call(mocks);
  await pumpPageWithProviders<T>(
    tester,
    pageWidget: pageWidget,
    providers: mocks.providers,
    mockViewModel: mockViewModel,
    mediaQueryData: mediaQueryData,
    navigatorObservers: navigatorObservers,
    router: router,
  );
  return mocks;
}
