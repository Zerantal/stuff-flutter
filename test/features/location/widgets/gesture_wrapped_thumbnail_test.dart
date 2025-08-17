// test/features/widgets/gesture_wrapped_thumbnail_test.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/domain/models/location_model.dart';
import 'package:stuff/features/location/widgets/gesture_wrapped_thumbnail.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/shared/Widgets/image_viewer/image_viewer_page.dart';

void main() {
  // dart format off
  // 1x1 transparent PNG bytes
  final Uint8List tinyPng = Uint8List.fromList(
      <int>[137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0,
        1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68,
        65, 84, 120, 156, 99, 96, 0, 0, 0, 2, 0, 1, 226, 33, 188, 33, 0, 0, 0,
        0, 73, 69, 78, 68, 174, 66, 96, 130,
      ]);
  // dart format on

  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('GestureWrappedThumbnail renders a Hero with provided tag', (tester) async {
    final Location dummyLocation = Location(name: 'Home');
    const heroTag = 'test_hero_tag';

    await tester.pumpWidget(
      wrap(
        GestureWrappedThumbnail(
          location: dummyLocation,
          images: const <ImageRef>[],
          heroTag: heroTag,
        ),
      ),
    );

    final heroFinder = find.byType(Hero);
    expect(heroFinder, findsOneWidget);

    final hero = tester.widget<Hero>(heroFinder);
    expect(hero.tag, equals(heroTag));
  });

  testWidgets('Tapping GestureWrappedThumbnail navigates to ImageViewerPage', (tester) async {
    final loc = Location(name: 'Lab');
    final images = <ImageRef>[ImageRef.memory(tinyPng)];
    const tag = 'loc_hero_tag';

    await tester.pumpWidget(
      wrap(GestureWrappedThumbnail(location: loc, images: images, heroTag: tag)),
    );

    // Tap the GestureDetect to open the viewer
    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    // Verify new route contains the ImageViewerPage
    expect(find.byType(ImageViewerPage), findsOneWidget);
  });
}
