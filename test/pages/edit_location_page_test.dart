import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

// Your app's imports
import 'package:stuff/pages/edit_location_page.dart';
import 'package:stuff/viewmodels/edit_location_view_model.dart';
import 'package:stuff/models/location_model.dart';
import 'package:stuff/services/data_service_interface.dart';
import 'package:stuff/services/image_data_service_interface.dart';
import 'package:stuff/services/location_service_interface.dart';
import 'package:stuff/services/image_picker_service_interface.dart';
import 'package:stuff/services/temporary_file_service_interface.dart';
import 'package:stuff/core/image_identifier.dart';
import 'Package:stuff/notifiers/app_bar_title_notifier.dart';
import 'package:stuff/main.dart';

// Import generated mocks
import 'edit_location_page_test.mocks.dart';

// Helper to disable verbose logging from the page during tests
void silencePageLogger() {
  Logger.root.level = Level.WARNING;
  Logger('EditLocationPage').level = Level.WARNING;
  Logger('EditLocationViewModel').level =
      Level.WARNING; // Also silence VM if noisy
}

// Renamed helper function
Future<void> setupWidgetWithProviders({
  required WidgetTester tester,
  required EditLocationViewModel viewModel,
  Location? initialLocation,
  MockNavigatorObserver? navigatorObserver,
  bool settleAfterPush = true,
}) async {
  final mockDataService = MockIDataService();
  final mockImageDataService = MockIImageDataService();
  final mockLocationService = MockILocationService();
  final mockImagePickerService = MockIImagePickerService();
  final mockTemporaryFileService = MockITemporaryFileService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        // Provide the services that EditLocationPage tries to obtain
        Provider<IDataService>.value(value: mockDataService),
        Provider<IImageDataService?>.value(value: mockImageDataService),
        Provider<ILocationService>.value(value: mockLocationService),
        Provider<IImagePickerService>.value(value: mockImagePickerService),
        Provider<ITemporaryFileService>.value(value: mockTemporaryFileService),
        ChangeNotifierProvider<AppBarTitleNotifier>(
          create: (_) => AppBarTitleNotifier(),
        ),
      ],
      child: MaterialApp(
        navigatorObservers: navigatorObserver != null
            ? [navigatorObserver]
            : [],
        home: const Scaffold(
          body: Text('Dummy Root Page'),
        ), // Dummy initial page
      ),
    ),
  );
  await tester.pumpAndSettle(); // Pump the dummy page

  // Push the EditLocationPage
  final NavigatorState navigator = tester.state(find.byType(Navigator));
  navigator.push(
    MaterialPageRoute(
      builder: (routeContext) {
        // Use a different context name to avoid confusion
        // Replicate the structure from AppRoutes.addLocation or AppRoutes.editLocation
        // This assumes AppBarTitleNotifier is also provided globally in your test setup
        // or that MyHomePageWrapper can handle it being null/has a default.
        // If AppBarTitleNotifier is critical for MyHomePageWrapper, ensure it's provided
        // in the MultiProvider in setupWidgetWithProviders.

        final bool isNew = initialLocation == null;
        final String appBarTitle = isNew
            ? 'Add New Location'
            : 'Edit Location'; // Or derive from initialLocation.name

        return ChangeNotifierProvider<EditLocationViewModel>.value(
          value: viewModel,
          child: MyHomePageWrapper(
            // <<< WRAP HERE
            appBarTitle: appBarTitle,
            showBackButton: true, // Typically true for edit pages
            initialPageBuilder: (wrapperContext) => EditLocationPage(
              initialLocation: initialLocation,
              viewModelOverride: viewModel,
              // DO NOT pass the updateAppBarTitle from here unless you mock/provide AppBarTitleNotifier
              // If EditLocationPage directly calls it, ensure it's handled or mocked.
              // It's better if EditLocationPage doesn't directly interact with AppBarTitleNotifier,
              // and lets MyHomePageWrapper handle the title based on ViewModel state or route args.
            ),
          ),
        );
      },
    ),
  );

  if (settleAfterPush) {
    // Ensure the pushed page is fully built and settled before returning.
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(); // do again for good measure
  }
}

@GenerateMocks([
  EditLocationViewModel,
  IDataService,
  IImageDataService,
  ILocationService,
  IImagePickerService,
  ITemporaryFileService,
])
@GenerateNiceMocks([MockSpec<NavigatorObserver>()])
void main() {
  hierarchicalLoggingEnabled = true;

  late MockEditLocationViewModel mockViewModel;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    silencePageLogger();
    mockViewModel = MockEditLocationViewModel();
    mockNavigatorObserver = MockNavigatorObserver();

    // --- Default stubs for the ViewModel ---
    // Default to empty controllers, specific tests can override
    when(mockViewModel.nameController).thenReturn(TextEditingController());
    when(
      mockViewModel.descriptionController,
    ).thenReturn(TextEditingController());
    when(mockViewModel.addressController).thenReturn(TextEditingController());
    when(mockViewModel.formKey).thenReturn(GlobalKey<FormState>());

    // Boolean flags
    when(mockViewModel.isNewLocation).thenReturn(true); // Default to new
    when(mockViewModel.isSaving).thenReturn(false);
    when(mockViewModel.isGettingLocation).thenReturn(false);
    when(mockViewModel.deviceHasLocationService).thenReturn(true);
    when(mockViewModel.locationPermissionDenied).thenReturn(false);

    // Image list
    when(mockViewModel.currentImages).thenReturn([]); // Default to empty

    // Methods (default void returns or simple futures)
    when(mockViewModel.saveLocation()).thenAnswer((_) async => true);
    when(mockViewModel.handleDiscardOrPop()).thenAnswer((_) async {});
    when(mockViewModel.getCurrentAddress()).thenAnswer((_) async {});
    when(mockViewModel.pickImageFromCamera()).thenAnswer((_) async {});
    when(mockViewModel.pickImageFromGallery()).thenAnswer((_) async {});
    when(mockViewModel.removeImage(any)).thenAnswer((_) async {});
    when(mockViewModel.addListener(any)).thenAnswer((invocation) {});
    when(mockViewModel.removeListener(any)).thenAnswer((invocation) {});
    when(
      mockViewModel.dispose(),
    ).thenAnswer((invocation) {}); // Important for ChangeNotifier
    when(mockViewModel.hasListeners).thenReturn(true); // Default to true

    when(
      mockViewModel.getImageThumbnailWidget(
        any,
        width: anyNamed('width'),
        height: anyNamed('height'),
        fit: anyNamed('fit'),
      ),
    ).thenAnswer((invocation) {
      final imageId = invocation.positionalArguments[0] as ImageIdentifier;
      if (imageId is GuidIdentifier && imageId.guid == 'guid1') {
        return Container(
          key: const ValueKey('fake_image_guid1'),
          width: 100,
          height: 100,
          color: Colors.blue,
        );
      } else if (imageId is TempFileIdentifier) {
        return Container(
          key: const ValueKey('fake_temp_image'),
          width: 100,
          height: 100,
          color: Colors.green,
        );
      }
      return const SizedBox(width: 100, height: 100); // Default placeholder
    });
  });

  tearDown(() {});

  group('EditLocationPage Rendering', () {
    testWidgets('renders correctly for a new location', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isNewLocation).thenReturn(true);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // This line is removed as setupWidgetWithProviders now handles it.

      expect(find.text('Add New Location'), findsOneWidget);
      expect(find.byKey(const ValueKey('addLocationButton')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, ''),
        findsNWidgets(3),
      ); // Name, Desc, Addr
      expect(find.text('No images yet. Add one!'), findsOneWidget);
    });

    testWidgets('renders correctly for an existing location', (
      WidgetTester tester,
    ) async {
      final existingLocation = Location(
        id: '1',
        name: 'Office',
        description: 'Workplace',
        address: '123 Tech Rd',
      );
      final nameCtrl = TextEditingController(text: existingLocation.name);
      final descCtrl = TextEditingController(
        text: existingLocation.description,
      );
      final addrCtrl = TextEditingController(text: existingLocation.address);

      when(mockViewModel.isNewLocation).thenReturn(false);
      when(mockViewModel.nameController).thenReturn(nameCtrl);
      when(mockViewModel.descriptionController).thenReturn(descCtrl);
      when(mockViewModel.addressController).thenReturn(addrCtrl);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        initialLocation: existingLocation,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing if setupWidgetWithProviders handles it

      expect(find.text('Edit Location'), findsOneWidget);
      expect(find.byKey(const ValueKey('saveLocationButton')), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Workplace'), findsOneWidget);
      expect(find.text('123 Tech Rd'), findsOneWidget);

      addTearDown(() {
        nameCtrl.dispose();
        descCtrl.dispose();
        addrCtrl.dispose();
      });
    });

    testWidgets('displays images for existing location', (
      WidgetTester tester,
    ) async {
      final imageId1 = GuidIdentifier('guid1');
      final existingLocation = Location(
        id: '1',
        name: 'Home',
        imageGuids: ['guid1'],
      );

      when(mockViewModel.isNewLocation).thenReturn(false);
      when(mockViewModel.currentImages).thenReturn([imageId1]);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        initialLocation: existingLocation,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Ensure images have time to build - Consider removing if setup handles it

      expect(find.byKey(const ValueKey('fake_image_guid1')), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('displays temp file image correctly', (
      WidgetTester tester,
    ) async {
      final tempFile = File('dummy_image.png');
      addTearDown(() async {
        await tester.runAsync(() async {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        });
      });

      await tester.runAsync(() async {
        await tempFile.writeAsBytes(
          Uint8List.fromList(List.generate(100, (index) => index)),
          flush: true,
        );
      });

      final imageId1 = TempFileIdentifier(tempFile);
      when(mockViewModel.currentImages).thenReturn([imageId1]);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows loading indicator when fetching address', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isGettingLocation).thenReturn(true);
      final addrCtrl = TextEditingController();
      when(mockViewModel.addressController).thenReturn(addrCtrl);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
        settleAfterPush: false,
      );

      // await tester.pump();

      final addressFieldFinder = find.widgetWithText(TextFormField, 'Address');
      expect(
        find.descendant(
          of: addressFieldFinder,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
        reason:
            "CircularProgressIndicator should be a descendant of the Address TextFormField "
            "when isGettingLocation is true. If this fails but the above expect passes, "
            "then the Address field is being built without the loading indicator despite the mock setup.",
      );
      addTearDown(addrCtrl.dispose);
    });

    testWidgets('shows location service unavailable message', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.deviceHasLocationService).thenReturn(false);
      final addrCtrl = TextEditingController();
      when(mockViewModel.addressController).thenReturn(addrCtrl);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      expect(
        find.text(
          'Device location service is unavailable or permission denied. Please check settings.',
        ),
        findsOneWidget,
      );
      addTearDown(addrCtrl.dispose);
    });
  });

  group('EditLocationPage Interactions', () {
    testWidgets('tapping Get Current Address calls ViewModel', (
      WidgetTester tester,
    ) async {
      final addrCtrl = TextEditingController();
      when(mockViewModel.addressController).thenReturn(addrCtrl);
      when(mockViewModel.deviceHasLocationService).thenReturn(true);
      when(mockViewModel.isGettingLocation).thenReturn(false);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      await tester.tap(find.byIcon(Icons.my_location));
      await tester.pumpAndSettle();

      verify(mockViewModel.getCurrentAddress()).called(1);
      addTearDown(addrCtrl.dispose);
    });

    testWidgets('tapping Camera icon calls pickImageFromCamera', (
      WidgetTester tester,
    ) async {
      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      verify(mockViewModel.pickImageFromCamera()).called(1);
    });

    testWidgets('tapping Gallery icon calls pickImageFromGallery', (
      WidgetTester tester,
    ) async {
      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      await tester.tap(find.byIcon(Icons.photo_library_outlined));
      verify(mockViewModel.pickImageFromGallery()).called(1);
    });

    testWidgets('tapping remove image calls viewModel.removeImage', (
      WidgetTester tester,
    ) async {
      final imageId1 = GuidIdentifier('guid1');
      when(mockViewModel.currentImages).thenReturn([imageId1]);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      verify(mockViewModel.removeImage(0)).called(1);
    });

    testWidgets(
      'tapping Save button calls saveLocation and shows SnackBar on success (new)',
      (WidgetTester tester) async {
        final nameCtrl = TextEditingController(text: 'Test Location Name');
        when(mockViewModel.nameController).thenReturn(nameCtrl);
        addTearDown(nameCtrl.dispose);

        when(mockViewModel.isNewLocation).thenReturn(true);
        when(mockViewModel.saveLocation()).thenAnswer((_) async => true);
        final formKey = GlobalKey<FormState>();
        when(mockViewModel.formKey).thenReturn(formKey);

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
        );
        // await tester.pumpAndSettle(); // Initial build of EditLocationPage - Consider removing

        await tester.tap(find.byKey(const ValueKey('addLocationButton')));
        await tester
            .pumpAndSettle(); // Allow saveLocation and SnackBar to process

        verify(mockViewModel.saveLocation()).called(1);
        expect(find.text('Location added.'), findsOneWidget);
        verify(mockNavigatorObserver.didPop(any, any)).called(1);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'tapping Save button calls saveLocation and shows SnackBar on failure',
      (WidgetTester tester) async {
        final nameCtrl = TextEditingController(
          text: 'Test Location Name for Failure',
        );
        when(mockViewModel.nameController).thenReturn(nameCtrl);
        addTearDown(nameCtrl.dispose);

        when(mockViewModel.saveLocation()).thenAnswer((_) async => false);
        final formKey = GlobalKey<FormState>();
        when(mockViewModel.formKey).thenReturn(formKey);

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          initialLocation: null,
          navigatorObserver: mockNavigatorObserver,
        );
        // await tester.pumpAndSettle(); // Consider removing

        await tester.tap(find.byKey(const ValueKey('addLocationButton')));
        await tester.pumpAndSettle();

        verify(mockViewModel.saveLocation()).called(1);
        expect(
          find.text('Failed to save location. Check details and try again.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping AppBar back button calls handleDiscardOrPop and pops',
      (WidgetTester tester) async {
        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        verify(mockViewModel.handleDiscardOrPop()).called(1);
        verify(mockNavigatorObserver.didPop(any, any)).called(1);
        await tester.pumpAndSettle();
      },
    );

    testWidgets('PopScope calls handleDiscardOrPop on system back', (
      WidgetTester tester,
    ) async {
      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        initialLocation: null,
        navigatorObserver: mockNavigatorObserver,
      );
      // await tester.pumpAndSettle(); // Consider removing

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      // Simulate system back button. This will trigger onPopInvoked.
      await navigator.maybePop();
      await tester.pumpAndSettle();

      verify(mockViewModel.handleDiscardOrPop()).called(1);
    });
  });

  group('Form Validation (Example - can be expanded)', () {
    testWidgets('shows error if location name is empty on save attempt', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> testFormKey = GlobalKey<FormState>();
      // Intentionally use an empty controller here to test validation
      final nameCtrl = TextEditingController();
      final descCtrl = TextEditingController();
      final addrCtrl = TextEditingController();

      when(mockViewModel.formKey).thenReturn(testFormKey);
      when(mockViewModel.nameController).thenReturn(nameCtrl);
      when(mockViewModel.descriptionController).thenReturn(descCtrl);
      when(mockViewModel.addressController).thenReturn(addrCtrl);
      when(mockViewModel.isNewLocation).thenReturn(true);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        navigatorObserver: mockNavigatorObserver,
      );

      await tester.tap(find.byKey(const ValueKey('addLocationButton')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a location name.'), findsOneWidget);
      verifyNever(mockViewModel.saveLocation());
      addTearDown(() {
        nameCtrl.dispose();
        descCtrl.dispose();
        addrCtrl.dispose();
      });
    });
  });
}
