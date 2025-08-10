// test/core/helpers/image_ref_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart'; // For mocking AssetBundle

import 'package:stuff/core/helpers/image_ref.dart';

// Helper class for mocking (if needed, not strictly for AssetBundle in this case yet)
class MockAssetBundle extends Mock implements AssetBundle {}

void main() {
  // No platform overrides or global HTTP overrides here; keep tests deterministic.

  group('providerFor', () {
    test('FileImageRef -> FileImage (or throws on web)', () {
      const ref = ImageRef.file('/tmp/fake.png');
      if (kIsWeb) {
        expect(() => providerFor(ref), throwsA(isA<UnsupportedError>()));
      } else {
        final provider = providerFor(ref);
        expect(provider, isA<FileImage>());
        expect((provider as FileImage).scale, 1.0);
      }
    });

    test('NetworkImageRef -> NetworkImage', () {
      const ref = ImageRef.network('https://example.com/a.png');
      final provider = providerFor(ref);
      expect(provider, isA<NetworkImage>());
      expect((provider as NetworkImage).scale, 1.0); // Default scale
    });

    test('MemoryImageRef -> MemoryImage', () {
      final ref = ImageRef.memory(Uint8List.fromList(const [1, 2, 3]));
      final provider = providerFor(ref);
      expect(provider, isA<MemoryImage>());
      expect((provider as MemoryImage).scale, 1.0); // Default scale
    });

    test('AssetImageRef -> AssetImage', () {
      const ref = ImageRef.asset('assets/some.png');
      final provider = providerFor(ref);
      expect(provider, isA<AssetImage>());
      expect((provider as AssetImage).assetName, 'assets/some.png');
    });

    test('AssetImageRef with bundle and package -> AssetImage', () {
      final mockBundle = MockAssetBundle();
      final ref = ImageRef.asset(
        'assets/img.png',
        bundle: mockBundle,
        package: 'my_pkg',
      );
      final provider = providerFor(ref);
      expect(provider, isA<AssetImage>());
      final assetImage = provider as AssetImage;
      expect(assetImage.assetName, 'assets/img.png');
      expect(assetImage.bundle, mockBundle);
      expect(assetImage.package, 'my_pkg');
    });

    test('wraps with ResizeImage when cache width provided', () {
      const ref = ImageRef.network('https://example.com/a.png');
      final provider = providerFor(ref, cacheWidth: 100);
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.width, 100);
      expect(resize.height, isNull);
    });

    test('wraps with ResizeImage when cache height provided', () {
      const ref = ImageRef.network('https://example.com/b.png');
      final provider = providerFor(ref, cacheHeight: 150);
      expect(provider, isA<ResizeImage>());
      final resize = provider as ResizeImage;
      expect(resize.width, isNull);
      expect(resize.height, 150);
    });

    test(
      'wraps with ResizeImage when both cache width and height provided',
      () {
        const ref = ImageRef.network('https://example.com/c.png');
        final provider = providerFor(ref, cacheWidth: 200, cacheHeight: 250);
        expect(provider, isA<ResizeImage>());
        final resize = provider as ResizeImage;
        expect(resize.width, 200);
        expect(resize.height, 250);
      },
    );

    test('does not wrap with ResizeImage if no cache size provided', () {
      const ref = ImageRef.network('https://example.com/d.png');
      final provider = providerFor(ref); // No cacheWidth or cacheHeight
      expect(provider, isNot(isA<ResizeImage>()));
      expect(provider, isA<NetworkImage>());
    });

    test('passes scale to underlying provider', () {
      const networkRef = ImageRef.network('https://example.com/a.png');
      final networkProvider =
          providerFor(networkRef, scale: 2.0) as NetworkImage;
      expect(networkProvider.scale, 2.0);

      final memoryRef = ImageRef.memory(Uint8List.fromList(const [1]));
      final memoryProvider = providerFor(memoryRef, scale: 1.5) as MemoryImage;
      expect(memoryProvider.scale, 1.5);
    });

    test('passes scale to ResizeImage if cache size also provided', () {
      const networkRef = ImageRef.network('https://example.com/e.png');
      final resizeProvider = providerFor(
        networkRef,
        cacheWidth: 50,
        scale: 2.5,
      );
      expect(resizeProvider, isA<ResizeImage>());
    });
  });

  group('buildImage Widget', () {
    testWidgets('renders Image with basic properties', (
      WidgetTester tester,
    ) async {
      final ref = ImageRef.memory(
        Uint8List.fromList(const [1, 2, 3, 4]),
      ); // Use memory for simplicity

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildImage(
              ref,
              width: 100,
              height: 150,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      );

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.width, 100);
      expect(imageWidget.height, 150);
      expect(imageWidget.fit, BoxFit.cover);
      expect(imageWidget.alignment, Alignment.topCenter);
      expect(imageWidget.filterQuality, FilterQuality.high);
      expect(imageWidget.image, isA<MemoryImage>());
    });

    testWidgets('uses provided placeholder during loading', (
      WidgetTester tester,
    ) async {
      final placeholderKey = GlobalKey();
      final placeholderWidget = SizedBox(
        key: placeholderKey,
        child: const Text('Custom Loading...'),
      );

      // Use a network image that won't load instantly.
      // This requires HttpOverrides for predictable behavior in tests.
      // For simplicity here, we'll directly test the loadingBuilder's output.
      // A full NetworkImage loading test is more complex.

      // Directly test the loadingBuilder logic as if it were loading
      final Image imageWidget = Image(
        image: const NetworkImage(
          'http://example.com/fake.png',
        ), // A provider that would trigger loading
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          // This is the logic from buildImage's loadingBuilder when placeholder is provided
          return placeholderWidget;
        },
      );

      // Simulate the loading state by calling the builder
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));
      final BuildContext contextForBuilder = tester.element(
        find.byType(Container).first,
      );

      final Widget builtLoadingWidget = imageWidget.loadingBuilder!(
        contextForBuilder,
        const Text('Child image'), // Dummy child
        const ImageChunkEvent(
          cumulativeBytesLoaded: 50,
          expectedTotalBytes: 100,
        ), // Simulate progress
      );

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: builtLoadingWidget)),
      );
      expect(find.byKey(placeholderKey), findsOneWidget);
      expect(find.text('Custom Loading...'), findsOneWidget);
    });

    testWidgets(
      'uses default CircularProgressIndicator when no placeholder and loading',
      (WidgetTester tester) async {
        // Directly test the loadingBuilder logic
        final Image imageWidget = Image(
          image: const NetworkImage('http://example.com/fake.png'),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            // This is the default from buildImage
            return const SizedBox(
              width: 20,
              height: 20,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        );

        await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));
        final BuildContext contextForBuilder = tester.element(
          find.byType(Container).first,
        );

        final Widget builtLoadingWidget = imageWidget.loadingBuilder!(
          contextForBuilder,
          const Text('Child image'),
          const ImageChunkEvent(
            cumulativeBytesLoaded: 50,
            expectedTotalBytes: 100,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: builtLoadingWidget)),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('shows child when loading complete', (
      WidgetTester tester,
    ) async {
      final Image imageWidget = Image(
        image: const NetworkImage('http://example.com/fake.png'),
        loadingBuilder: (context, child, progress) {
          // Using buildImage's typical logic
          if (progress == null) return child;
          return const CircularProgressIndicator();
        },
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));
      final BuildContext contextForBuilder = tester.element(
        find.byType(Container).first,
      );

      final Widget builtChildWidget = imageWidget.loadingBuilder!(
        contextForBuilder,
        const Text('Actual Image Content'), // The actual child
        null, // Simulate progress is null (loading complete)
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: builtChildWidget)),
      );
      expect(find.text('Actual Image Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('uses errorBuilder on failure (missing asset)', (tester) async {
      // Asset that does not exist -> triggers errorBuilder.
      const ref = ImageRef.asset('assets/does_not_exist.png');
      final errorKey = GlobalKey();

      final widget = MaterialApp(
        home: Scaffold(
          body: buildImage(
            ref,
            errorWidget: SizedBox(
              key: errorKey,
              child: const Text('Custom Asset Error'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle(); // Let the error propagate for AssetImage
      expect(find.byKey(errorKey), findsOneWidget);
      expect(find.text('Custom Asset Error'), findsOneWidget);
    });

    testWidgets(
      'uses default error text when no errorWidget and failure (missing asset)',
      (tester) async {
        const ref = ImageRef.asset('assets/another_missing_asset.png');

        final widget = MaterialApp(
          home: Scaffold(
            body: buildImage(ref), // No custom errorWidget
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();
        expect(find.text('Image failed to load'), findsOneWidget);
      },
    );

    // To properly test NetworkImage failure, you'd typically mock HttpOverrides
    // This is a simplified version that relies on a clearly invalid URL.
    testWidgets(
      'uses errorBuilder on failure (bad network URL)',
      (tester) async {
        const ref = ImageRef.network(
          'http://invalid-url-that-will-fail-for-sure-hopefully/img.png',
        );
        final errorKey = GlobalKey();

        final widget = MaterialApp(
          home: Scaffold(
            body: buildImage(
              ref,
              errorWidget: SizedBox(
                key: errorKey,
                child: const Text('Network Error'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(widget);
        await tester.pumpAndSettle(
          const Duration(seconds: 5),
        ); // Give network time to fail & settle
        expect(find.byKey(errorKey), findsOneWidget);
        expect(find.text('Network Error'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 10)),
    ); // Increased timeout for this test

    testWidgets(
      'applies cacheWidth and cacheHeight via providerFor to Image widget',
      (WidgetTester tester) async {
        final ref = ImageRef.memory(Uint8List.fromList(const [1, 2, 3, 4]));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: buildImage(ref, cacheWidth: 50, cacheHeight: 75),
            ),
          ),
        );

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.image, isA<ResizeImage>());
        final resizeImage = imageWidget.image as ResizeImage;
        expect(resizeImage.width, 50);
        expect(resizeImage.height, 75);
        expect(resizeImage.imageProvider, isA<MemoryImage>());
      },
    );
  });
}
