// test/utils/ui_runner_helper.dart
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

// -------- Mocks bundle -------------------------------------------------------

class TestAppMocks {
  final MockIDataService dataService;
  final MockIImageDataService imageDataService;
  final MockILocationService locationService;
  final MockITemporaryFileService temporaryFileService;
  final MockIImagePickerService imagePickerService;

  TestAppMocks()
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

// Typedefs to make intent obvious
typedef NotifierVmFactory<T extends ChangeNotifier> = T Function(TestAppMocks m);
typedef ContextVmFactory<T> = T Function(TestAppMocks m, BuildContext ctx);
typedef PlainVmFactory<T> = T Function(TestAppMocks m);
typedef AfterInit<T> = Future<void> Function(T vm, TestAppMocks m);

// -------- Core pump (router-aware, provider-scoped) --------------------------

/// Pumps an app that injects [providers] inside the MaterialApp( .router ) builder,
/// so everything the Navigator/Router renders can read them.
///
/// - If [router] is null, [home] is used as the page under test.
/// - If [router] is provided, [home] is ignored; Router decides the page.
Future<void> pumpApp(
  WidgetTester tester, {
  Widget? home,
  List<SingleChildWidget> providers = const [],
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
}) async {
  Widget wrap(Widget? child) {
    // Always give the tree a MediaQuery
    final inner = MediaQuery(
      data: mediaQueryData ?? const MediaQueryData(),
      child: child ?? const SizedBox.shrink(),
    );

    // Only wrap with MultiProvider when we actually have providers
    if (providers.isEmpty) return inner;

    return MultiProvider(providers: providers, child: inner);
  }

  if (router == null) {
    assert(home != null, 'pumpApp: `home` is required when `router` is null.');

    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => home!,
        ),
      ],
      // 👇 attach test observers here
      observers: [...navigatorObservers],
    );
  }

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => wrap(child),
    ),
  );
}

// -------- Convenience: mocks only -------------------------------------------

/// Creates the common mocks, stubs them via [onMocksReady], then pumps an app
/// with those mocks provided. Returns the mocks for further use in the test.
Future<TestAppMocks> pumpAppWithMocks(
  WidgetTester tester, {
  Widget? home,
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
  void Function(TestAppMocks m)? onMocksReady,
  List<SingleChildWidget> additionalProviders = const [],
}) async {
  final mocks = TestAppMocks();
  onMocksReady?.call(mocks);

  await pumpApp(
    tester,
    home: home,
    providers: [...mocks.providers, ...additionalProviders],
    mediaQueryData: mediaQueryData,
    navigatorObservers: navigatorObservers,
    router: router,
  );
  return mocks;
}

// -------- ChangeNotifier VM helper ------------------------------------------

class PumpedNotifierVm<T extends ChangeNotifier> {
  final T vm;
  final TestAppMocks mocks;
  const PumpedNotifierVm({required this.vm, required this.mocks});
}

/// Builds a real ChangeNotifier VM from mocks, provides it, pumps the app,
/// and optionally runs [afterInit] AFTER the provider is mounted.
Future<PumpedNotifierVm<T>> pumpWithNotifierVm<T extends ChangeNotifier>(
  WidgetTester tester, {
  required Widget home,
  NotifierVmFactory<T>? vmFactory,
  ContextVmFactory<T>? contextVmFactory,
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
  void Function(TestAppMocks m)? onMocksReady,
  AfterInit<T>? afterInit,
  List<SingleChildWidget> additionalProviders = const [],
}) async {
  assert(
    vmFactory != null || contextVmFactory != null,
    'You must provide either vmFactory or contextVmFactory',
  );

  final mocks = TestAppMocks();
  onMocksReady?.call(mocks);

  late T vm;

  await pumpApp(
    tester,
    home: Builder(
      builder: (ctx) {
        if (contextVmFactory != null) {
          vm = contextVmFactory(mocks, ctx);
        } else {
          vm = vmFactory!(mocks);
        }

        return ChangeNotifierProvider<T>.value(value: vm, child: home);
      },
    ),
    providers: [...mocks.providers, ...additionalProviders],
    mediaQueryData: mediaQueryData,
    navigatorObservers: navigatorObservers,
    router: router,
  );

  if (afterInit != null) {
    await afterInit(vm, mocks);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  return PumpedNotifierVm(vm: vm, mocks: mocks);
}

// -------- Plain (non-ChangeNotifier) VM helper -------------------------------

class PumpedPlainVm<T> {
  final T vm;
  final TestAppMocks mocks;
  const PumpedPlainVm({required this.vm, required this.mocks});
}

/// Builds a real plain VM from mocks, provides it (with optional dispose hook),
/// pumps the app, and optionally runs [afterInit] AFTER mount.
Future<PumpedPlainVm<T>> pumpWithPlainVm<T>(
  WidgetTester tester, {
  required Widget home,
  required PlainVmFactory<T> vmFactory,
  MediaQueryData? mediaQueryData,
  List<NavigatorObserver> navigatorObservers = const [],
  GoRouter? router,
  void Function(TestAppMocks m)? onMocksReady,
  AfterInit<T>? afterInit,
  void Function(T vm)? onDispose,
  List<SingleChildWidget> additionalProviders = const [],
}) async {
  final mocks = TestAppMocks();
  onMocksReady?.call(mocks);

  final vm = vmFactory(mocks);

  await pumpApp(
    tester,
    home: home,
    providers: [
      ...mocks.providers,
      ...additionalProviders,
      Provider<T>(create: (_) => vm, dispose: (_, v) => onDispose?.call(v)),
    ],
    mediaQueryData: mediaQueryData,
    navigatorObservers: navigatorObservers,
    router: router,
  );

  if (afterInit != null) {
    await afterInit(vm, mocks);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  return PumpedPlainVm(vm: vm, mocks: mocks);
}
