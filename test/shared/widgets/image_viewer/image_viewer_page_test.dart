// test/shared/widgets/image_viewer_page_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/shared/widgets/image_viewer/image_viewer_page.dart';
import 'package:stuff/shared/widgets/image_viewer/image_viewer_utils.dart';

void main() {
  group('ImageViewerPage basics', () {
    testWidgets('renders initial index and updates on swipe', (tester) async {
      final images = [const ImageRef.asset('assets/a.png'), const ImageRef.asset('assets/b.png')];

      await tester.pumpWidget(MaterialApp(home: ImageViewerPage(images: images, initialIndex: 0)));

      expect(find.text('1 / 2'), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(-400, 0), 500);
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('toggles chrome (app bar) on tap', (tester) async {
      final images = [const ImageRef.asset('assets/a.png')];

      await tester.pumpWidget(MaterialApp(home: ImageViewerPage(images: images)));

      expect(find.byType(AppBar), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
    });

    testWidgets('shows page dots when >1 image', (tester) async {
      final images = [const ImageRef.asset('assets/a.png'), const ImageRef.asset('assets/b.png')];

      await tester.pumpWidget(MaterialApp(home: ImageViewerPage(images: images)));

      expect(
        find.byWidgetPredicate((w) => w.runtimeType.toString() == '_PageDots'),
        findsOneWidget,
      );
    });

    testWidgets('supports hero tags', (tester) async {
      final images = [const ImageRef.asset('a.png'), const ImageRef.asset('b.png')];
      final tags = ['h1', 'h2'];

      await tester.pumpWidget(
        MaterialApp(
          home: ImageViewerPage(images: images, heroTags: tags),
        ),
      );

      // Initially only the first page is built
      expect(find.byType(Hero), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Hero && w.tag == 'h1'), findsOneWidget);

      // Swipe to second page
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      // Now the second hero should exist
      expect(find.byWidgetPredicate((w) => w is Hero && w.tag == 'h2'), findsOneWidget);
    });
  });

  group('defaultNameForRef', () {
    test('returns suggestedBaseName when provided', () {
      final name = defaultNameForRef(const ImageRef.asset('assets/a.png'), 1, baseName: 'Base');
      expect(name, 'Base_1.jpg');
    });

    test('generates names for each ImageRef type', () {
      final refs = <ImageRef>[
        const FileImageRef('/tmp/photo.png'),
        const NetworkImageRef('https://x.com/photo.jpg?param=1'),
        const AssetImageRef('assets/img.png'),
        MemoryImageRef(Uint8List.fromList([1, 2, 3])),
      ];

      expect(defaultNameForRef(refs[0], 0), 'photo.png');
      expect(defaultNameForRef(refs[1], 1), 'photo.jpg');
      expect(defaultNameForRef(refs[2], 2), 'img.png');
      expect(defaultNameForRef(refs[3], 3), 'image_3.jpg');
    });
  });
}
