// test/shared/image/image_ref_test.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/shared/image/image_ref.dart';

void main() {
  group('ImageRef equality', () {
    test('FileImageRef normalizes slashes', () {
      final a = const FileImageRef('C:\\foo\\bar.png');
      final b = const FileImageRef('C:/foo/bar.png');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('NetworkImageRef equality by url', () {
      final a = const NetworkImageRef('https://x');
      final b = const NetworkImageRef('https://x');
      final c = const NetworkImageRef('https://y');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('MemoryImageRef equality by digest + length', () {
      final a = MemoryImageRef(Uint8List.fromList([1, 2, 3]));
      final b = MemoryImageRef(Uint8List.fromList([1, 2, 3]));
      final c = MemoryImageRef(Uint8List.fromList([1, 2, 3, 4]));
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('AssetImageRef equality by assetName + package', () {
      const a = AssetImageRef('assets/x.png', package: 'pkg');
      const b = AssetImageRef('assets/x.png', package: 'pkg');
      const c = AssetImageRef('assets/x.png');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('providerFor', () {
    test('returns correct provider types', () {
      expect(providerFor(const FileImageRef('foo')), isA<ImageProvider>());
      expect(providerFor(const NetworkImageRef('https://x')), isA<NetworkImage>());
      expect(providerFor(MemoryImageRef(Uint8List(1))), isA<MemoryImage>());
      expect(providerFor(const AssetImageRef('assets/x.png')), isA<AssetImage>());
    });

    test('wraps with ResizeImage if cacheWidth or cacheHeight specified', () {
      final ref = const NetworkImageRef('https://x');
      final p = providerFor(ref, cacheWidth: 50);
      expect(p, isA<ResizeImage>());
    });
  });

  group('buildImage widget', () {
    testWidgets('renders with default loading + error widgets', (tester) async {
      const ref = NetworkImageRef('http://does-not-exist');
      final widget = buildImage(ref, width: 10, height: 10);

      await tester.pumpWidget(MaterialApp(home: widget));

      final image = widget as Image;
      final ctx = tester.element(find.byType(Image));

      // Simulate loading: non-null progress => should return default spinner
      final loading = image.loadingBuilder!(
        ctx,
        const SizedBox(),
        const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 10),
      );

      // Pump the loading widget into the tree and assert
      await tester.pumpWidget(MaterialApp(home: loading));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate error: should return default error widget
      final error = image.errorBuilder!(ctx, Exception('fail'), StackTrace.empty);
      await tester.pumpWidget(MaterialApp(home: error));
      expect(find.textContaining('Image failed to load'), findsOneWidget);
    });

    testWidgets('uses custom loading and error widgets if provided', (tester) async {
      const ref = NetworkImageRef('http://example');
      final widget = buildImage(
        ref,
        loadingWidget: const Text('Loading...'),
        errorWidget: const Text('Error!'),
      );

      await tester.pumpWidget(MaterialApp(home: widget));

      final image = widget as Image;
      final ctx = tester.element(find.byType(Image));

      // Simulate loading with custom widget
      final loading = image.loadingBuilder!(
        ctx,
        const SizedBox(),
        const ImageChunkEvent(cumulativeBytesLoaded: 0, expectedTotalBytes: 10),
      );
      await tester.pumpWidget(MaterialApp(home: loading));
      expect(find.text('Loading...'), findsOneWidget);

      // Simulate error with custom widget
      final error = image.errorBuilder!(ctx, Exception('fail'), StackTrace.empty);
      await tester.pumpWidget(MaterialApp(home: error));
      expect(find.text('Error!'), findsOneWidget);
    });
  });
}
