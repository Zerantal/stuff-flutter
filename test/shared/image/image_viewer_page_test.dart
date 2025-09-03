import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/ui_runner_helper.dart'; // pumpApp()

// TODO: Point this at the actual location of ImageViewerPage in your repo.
import 'package:stuff/shared/widgets/image_viewer/image_viewer_page.dart';
import 'package:stuff/shared/image/image_ref.dart';

// dart format off
// --- A tiny valid 1x1 PNG so MemoryImage works in tests (no network/plugins).
const List<int> _k1x1TransparentPng = <int>[
  0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0x00,0x00,0x00,0x0D,0x49,0x48,0x44,0x52,
  0x00,0x00,0x00,0x01,0x00,0x00,0x00,0x01,0x08,0x06,0x00,0x00,0x00,0x1F,0x15,0xC4,
  0x89,0x00,0x00,0x00,0x0A,0x49,0x44,0x41,0x54,0x78,0x9C,0x63,0xF8,0xCF,0xC0,0x00,
  0x00,0x03,0x01,0x01,0x00,0x18,0xDD,0x8D,0xB1,0x00,0x00,0x00,0x00,0x49,0x45,0x4E,
  0x44,0xAE,0x42,0x60,0x82,
];
// dart format on

ImageRef _memPng() => ImageRef.memory(Uint8List.fromList(_k1x1TransparentPng));

// --- Finders/helpers ---------------------------------------------------------

Finder _saveButton() => find.byTooltip('Save to device');
Finder _shareButton() => find.byTooltip('Share');

Finder _dotsRowFinder() => find.byWidgetPredicate(
  (w) => w is Row && w.children.isNotEmpty && w.children.every((c) => c is AnimatedContainer),
  description: 'Row of indicator dots',
);

int _dotCount(WidgetTester tester) {
  final row = tester.widget<Row>(_dotsRowFinder());
  return row.children.whereType<AnimatedContainer>().length;
}

/// Returns the laid-out widths of all dot AnimatedContainers under the row.
List<double> _dotWidths(WidgetTester tester) {
  final row = _dotsRowFinder();
  expect(row, findsOneWidget, reason: 'Dots row not found');

  final dots = find.descendant(of: row, matching: find.byType(AnimatedContainer));

  // Read size from each dot's RenderBox.
  return dots
      .evaluate()
      .map((element) {
        final rb = element.renderObject as RenderBox;
        return rb.size.width;
      })
      .toList(growable: false);
}

// --- Tests -------------------------------------------------------------------

void main() {
  group('ImageViewerPage', () {
    testWidgets('shows title "index / count" and updates on swipe', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng(), _memPng()];

      await pumpApp(tester, home: ImageViewerPage(images: images, initialIndex: 0));

      expect(find.text('1 / 3'), findsOneWidget);

      // Swipe left → next page
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('indicator shows one dot per image and active dot is wider', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng(), _memPng(), _memPng()];

      await pumpApp(tester, home: ImageViewerPage(images: images, initialIndex: 1));

      final dotsRow = _dotsRowFinder();
      expect(dotsRow, findsOneWidget);
      expect(_dotCount(tester), images.length);

      final widths = _dotWidths(tester);
      final nonNull = widths.whereType<double>().toList();
      expect(nonNull.isNotEmpty, isTrue);
      expect(
        nonNull.reduce((a, b) => a > b ? a : b),
        greaterThan(nonNull.reduce((a, b) => a < b ? a : b)),
      );
    });

    testWidgets('tapping image toggles chrome (AppBar & dots)', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng()];

      await pumpApp(tester, home: ImageViewerPage(images: images, initialIndex: 0));

      // Initially visible
      expect(find.byType(AppBar), findsOneWidget);
      expect(_dotsRowFinder(), findsOneWidget);

      // Tap to hide chrome
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      expect(_dotsRowFinder(), findsNothing);

      // Tap again to show chrome
      await tester.tap(find.byType(InteractiveViewer));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(_dotsRowFinder(), findsOneWidget);
    });

    testWidgets('initialIndex is clamped to valid range', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng()];

      await pumpApp(tester, home: ImageViewerPage(images: images, initialIndex: 99));

      // Should show the last page
      expect(find.text('2 / 2'), findsOneWidget);

      // Active dot should be at the last index (wider width there)
      final widths = _dotWidths(tester).whereType<double>().toList();
      final maxW = widths.reduce((a, b) => a > b ? a : b);
      expect(widths.last, maxW);
    });

    testWidgets('wraps page in Hero when heroTags are provided', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng()];
      final tags = ['img-0', 'img-1'];

      await pumpApp(
        tester,
        home: ImageViewerPage(images: images, initialIndex: 0, heroTags: tags),
      );

      final hero = find.byType(Hero);
      expect(hero, findsWidgets);

      // Verify the first Hero has the expected tag
      final firstHero = tester.widget<Hero>(hero.first);
      expect(firstHero.tag, anyOf('img-0', 'img-1')); // page 0 or current visible may wrap
    });

    testWidgets('pressing Share shows a SnackBar in test env', (tester) async {
      final images = <ImageRef>[_memPng()];

      await pumpApp(
        tester,
        home: Scaffold(body: ImageViewerPage(images: images, initialIndex: 0)),
      );

      await tester.tap(_shareButton());
      await tester.pump(); // show SnackBar

      // In a widget test, platform channels/plugins typically throw → caught → "Share failed".
      expect(find.text('Share failed'), findsOneWidget);
    });

    testWidgets('pressing Save shows a SnackBar in test env', (tester) async {
      final images = <ImageRef>[_memPng()];

      await pumpApp(
        tester,
        home: Scaffold(body: ImageViewerPage(images: images, initialIndex: 0)),
      );

      await tester.tap(_saveButton());
      await tester.pump();

      // On test host (not Android/iOS/web), desktop path calls file_selector; without plugin it throws → "Save failed".
      expect(find.text('Save failed'), findsOneWidget);
    });

    testWidgets('swiping changes which dot is active', (tester) async {
      final images = <ImageRef>[_memPng(), _memPng(), _memPng()];

      await pumpApp(tester, home: ImageViewerPage(images: images, initialIndex: 0));

      final before = _dotWidths(tester);

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      final after = _dotWidths(tester);
      expect(after, isNot(equals(before)));
    });

    testWidgets('hides dots when only one image', (tester) async {
      await pumpApp(tester, home: ImageViewerPage(images: [_memPng()], initialIndex: 0));
      // AppBar still shows "1 / 1"
      expect(find.text('1 / 1'), findsOneWidget);
      // Dots row shouldn’t exist
      expect(
        find.byWidgetPredicate((w) => w is Row && w.children.every((c) => c is AnimatedContainer)),
        findsNothing,
      );
    });

    testWidgets('asserts when heroTags length != images length', (tester) async {
      expect(
        () => ImageViewerPage(images: [_memPng(), _memPng()], heroTags: ['only-one']),
        throwsAssertionError,
      );
    });
  });
}
