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
      ],
      child: MaterialApp(
        navigatorObservers: navigatorObserver != null
            ? [navigatorObserver]
            : [],
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditLocationPage(
                        initialLocation: initialLocation,
                        viewModelOverride: viewModel,
                      ),
                    ),
                  );
                },
                child: const Text('Go to Edit Location Page'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Go to Edit Location Page'));

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
    when(mockViewModel.isPickingImage).thenReturn(false);
    when(mockViewModel.hasUnsavedChanges).thenReturn(false);

    // Image list
    when(mockViewModel.currentImages).thenReturn([]); // Default to empty

    // Methods (default void returns or simple futures)
    when(mockViewModel.saveLocation()).thenAnswer((_) async => true);
    when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((_) async {});
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

      expect(find.text('Add New Location'), findsOneWidget);
      expect(find.byKey(const ValueKey('addLocationButton')), findsOneWidget);

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.arrow_back),
        ),
        findsOneWidget,
      );

      // The "No images yet. Add one!" text is inside ImageManagerInput widget.
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

      final addressFieldFinder = find.widgetWithText(TextFormField, 'Address');
      expect(
        find.descendant(
          of: addressFieldFinder,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
        reason:
            "CircularProgressIndicator should be a descendant of the Address TextFormField "
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
        when(mockViewModel.isPickingImage).thenReturn(false);

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.tap(find.byKey(const ValueKey('addLocationButton')));
        await tester.pumpAndSettle();

        verify(mockViewModel.saveLocation()).called(1);
        expect(find.text('Location added.'), findsOneWidget);
        verify(mockNavigatorObserver.didPop(any, any)).called(1);
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
        when(mockViewModel.isPickingImage).thenReturn(false);

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          initialLocation: null,
          navigatorObserver: mockNavigatorObserver,
        );

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
        // EditLocationPage Interactions
        // Test: tapping AppBar back button calls handleDiscardOrPop and pops

        // Ensure that when handleDiscardOrPop is called, it simulates a pop
        when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((
          invocation,
        ) async {
          final context = invocation.positionalArguments[0] as BuildContext;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        when(mockViewModel.isPickingImage).thenReturn(false);
        when(mockViewModel.isSaving).thenReturn(false);
        when(mockViewModel.hasUnsavedChanges).thenReturn(false);

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        verify(mockViewModel.handleDiscardOrPop(any)).called(1);
        verify(mockNavigatorObserver.didPop(any, any)).called(1);
      },
    );

    testWidgets(
      'tapping AppBar back button with unsaved changes shows dialog, user discards, and pops',
      (WidgetTester tester) async {
        when(mockViewModel.isPickingImage).thenReturn(false);
        when(mockViewModel.isSaving).thenReturn(false);
        when(
          mockViewModel.hasUnsavedChanges,
        ).thenReturn(true); // HAS unsaved changes

        when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((
          invocation,
        ) async {
          final context = invocation.positionalArguments[0] as BuildContext;
          // TODO: need to find vm dialog and tap its Discard

          Future.delayed(Duration.zero, () {
            // Allow current frame to build
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(); // Simulate pop after "discard"
            }
          });
        });

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        verify(mockViewModel.handleDiscardOrPop(any)).called(1);

        verify(
          mockNavigatorObserver.didPop(any, any),
        ).called(1); // Ensure pop occurred
      },
    );

    testWidgets(
      'tapping AppBar back button does NOT pop if isPickingImage is true',
      (WidgetTester tester) async {
        when(mockViewModel.isPickingImage).thenReturn(true);
        when(mockViewModel.isSaving).thenReturn(false);
        when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((_) async {});

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          navigatorObserver: mockNavigatorObserver,
          settleAfterPush: false,
        );

        // Expect the EditLocationPage to be present
        expect(find.byType(EditLocationPage), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump(); // Allow PopScope to evaluate

        verify(mockViewModel.handleDiscardOrPop(any)).called(1);
        verifyNever(
          mockNavigatorObserver.didPop(any, any),
        ); // Should not have popped
        expect(
          find.byType(EditLocationPage),
          findsOneWidget,
        ); // Still on the page
      },
    );

    testWidgets('PopScope calls handleDiscardOrPop on system back', (
      WidgetTester tester,
    ) async {
      // EditLocationPage Interactions
      // Test: PopScope calls handleDiscardOrPop on system back
      // PopScope's onPopInvoked will call handleDiscardOrPop.
      // We mock handleDiscardOrPop to perform a pop to verify the full flow.
      when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((
        invocation,
      ) async {
        final context = invocation.positionalArguments[0] as BuildContext;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      when(mockViewModel.isPickingImage).thenReturn(false); // Allow pop
      when(mockViewModel.isSaving).thenReturn(false); // Allow pop
      when(mockViewModel.hasUnsavedChanges).thenReturn(true);

      await setupWidgetWithProviders(
        tester: tester,
        viewModel: mockViewModel,
        initialLocation: null,
        navigatorObserver: mockNavigatorObserver,
      );

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      // Simulate system back button. This will trigger onPopInvoked.
      await navigator.maybePop();
      await tester.pumpAndSettle();

      verify(mockViewModel.handleDiscardOrPop(any)).called(1);
      verify(
        mockNavigatorObserver.didPop(any, any),
      ).called(1); // Ensure pop occurred
    });

    testWidgets(
      'PopScope pops directly on system back if NO unsaved changes and not busy',
      (WidgetTester tester) async {
        when(mockViewModel.isPickingImage).thenReturn(false);
        when(mockViewModel.isSaving).thenReturn(false);
        when(
          mockViewModel.hasUnsavedChanges,
        ).thenReturn(false); // PopScope's canPop will be true

        // handleDiscardOrPop should NOT be called by PopScope in this case
        when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((_) async {});

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          initialLocation: null,
          navigatorObserver: mockNavigatorObserver,
        );

        final NavigatorState navigator = tester.state(find.byType(Navigator));
        await navigator
            .maybePop(); // Simulate system back. PopScope allows direct pop.
        await tester.pumpAndSettle();

        // Because canPop was true, onPopInvoked was called with didPop: true,
        // so it should NOT have called handleDiscardOrPop.
        verifyNever(mockViewModel.handleDiscardOrPop(any));
        verify(
          mockNavigatorObserver.didPop(any, any),
        ).called(1); // Pop occurred directly
      },
    );

    testWidgets(
      'PopScope does NOT call handleDiscardOrPop or pop if isPickingImage is true on system back',
      (WidgetTester tester) async {
        // EditLocationPage Interactions
        // Test: PopScope does NOT call handleDiscardOrPop or pop if isPickingImage is true on system back

        when(mockViewModel.isPickingImage).thenReturn(true);
        when(mockViewModel.isSaving).thenReturn(false);
        when(mockViewModel.hasUnsavedChanges).thenReturn(false);
        // PopScope's onPopInvoked will call handleDiscardOrPop.
        when(mockViewModel.handleDiscardOrPop(any)).thenAnswer((_) async {});

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
          initialLocation: null,
          navigatorObserver: mockNavigatorObserver,
          settleAfterPush: false,
        );

        final NavigatorState navigator = tester.state(find.byType(Navigator));
        await navigator.maybePop(); // Attempt system back
        await tester.pump(); // Let PopScope do its work

        // handleDiscardOrPop *is* called by PopScope's onPopInvoked callback.
        verify(mockViewModel.handleDiscardOrPop(any)).called(1);
        verifyNever(
          mockNavigatorObserver.didPop(any, any),
        ); // But no pop should occur

        verifyNever(mockViewModel.handleDiscardOrPop(any));
        // Check that the page is still there (did not pop)
        expect(find.byType(EditLocationPage), findsOneWidget);
      },
    );
  });

  group('Form Validation (Example - can be expanded)', () {
    testWidgets('shows error if location name is empty on save attempt', (
      WidgetTester tester,
    ) async {
      // Form Validation (Example - can be expanded)
      // Test: shows error if location name is empty on save attempt
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

  group('Action Button State', () {
    testWidgets(
      'Save button is disabled and shows no icon when isSaving is true',
      (WidgetTester tester) async {
        when(mockViewModel.isSaving).thenReturn(true);
        when(
          mockViewModel.isNewLocation,
        ).thenReturn(false); // For "Save Changes" button

        await setupWidgetWithProviders(
          tester: tester,
          viewModel: mockViewModel,
        );

        final Finder buttonFinder = find.byKey(
          const ValueKey('saveLocationButton'),
        );
        expect(buttonFinder, findsOneWidget);

        final ElevatedButton button = tester.widget<ElevatedButton>(
          buttonFinder,
        );
        expect(
          button.onPressed,
          isNull,
          reason: "Button should be disabled when isSaving is true",
        );

        // Check that the icon is an empty Container when isSaving is true
        expect(
          find.descendant(of: buttonFinder, matching: find.byType(Icon)),
          findsNothing,
        );
        expect(
          find.descendant(of: buttonFinder, matching: find.byType(Container)),
          findsWidgets,
        ); // Expecting at least the empty container for the icon
      },
    );

    testWidgets('Add Location button shows correct icon when not saving', (
      WidgetTester tester,
    ) async {
      when(mockViewModel.isSaving).thenReturn(false);
      when(mockViewModel.isNewLocation).thenReturn(true);
      await setupWidgetWithProviders(tester: tester, viewModel: mockViewModel);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('addLocationButton')),
          matching: find.byIcon(Icons.add_circle_outline),
        ),
        findsOneWidget,
      );
    });
  });
}
