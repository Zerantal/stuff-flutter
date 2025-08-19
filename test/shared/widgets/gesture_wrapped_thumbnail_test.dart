import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/shared/widgets/gesture_wrapped_thumbnail.dart';
import 'package:stuff/shared/widgets/image_thumb.dart';
import 'package:stuff/shared/widgets/image_viewer/image_viewer_page.dart';
import 'package:stuff/shared/image/image_ref.dart';

class _TestObserver extends NavigatorObserver {
  Route<dynamic>? lastPushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) lastPushed = route;

    super.didPush(route, previousRoute);
  }
}

Widget _wrap(Widget child, {NavigatorObserver? observer}) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
    navigatorObservers: observer != null ? [observer] : const <NavigatorObserver>[],
  );
}

void main() {
  const img = ImageRef.asset('assets/does_not_need_to_exist.png');

  testWidgets('renders ImageThumb with default size and hero tag from entityId', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GestureWrappedThumbnail(
          images: [img],
          entityId: 'abc',
          entityName: 'Name',
          size: 64, // width/height fallback
        ),
      ),
    );

    // ImageThumb is created with key using entityId
    final thumb = tester.widget<ImageThumb>(find.byKey(const Key('thumb_abc')));
    expect(thumb.width, 64);
    expect(thumb.height, 64);

    // Hero tag should default to 'ent_<entityId>_img0'
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'ent_abc_img0');
  });

  testWidgets('uses explicit width/height when provided', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const GestureWrappedThumbnail(
          images: [img],
          entityId: 'abc',
          width: 40,
          height: 50,
          size: 64, // ignored because width/height are set
        ),
      ),
    );
    final thumb = tester.widget<ImageThumb>(find.byType(ImageThumb));
    expect(thumb.width, 40);
    expect(thumb.height, 50);
  });

  testWidgets('passes placeholder to ImageThumb when provided', (tester) async {
    const ph = ImageRef.asset('assets/placeholder.png');
    await tester.pumpWidget(
      _wrap(const GestureWrappedThumbnail(images: [img], entityId: 'abc', placeholder: ph)),
    );
    final thumb = tester.widget<ImageThumb>(find.byType(ImageThumb));
    expect(thumb.placeholderWidget, isNotNull);
  });

  testWidgets('uses custom heroTag when provided', (tester) async {
    await tester.pumpWidget(
      _wrap(const GestureWrappedThumbnail(images: [img], entityId: 'abc', heroTag: 'customHero')),
    );
    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, 'customHero');
  });

  testWidgets('tap pushes ImageViewerPage when images is not empty', (tester) async {
    final obs = _TestObserver();
    await tester.pumpWidget(
      _wrap(
        const GestureWrappedThumbnail(images: [img], entityId: 'abc', entityName: 'Name'),
        observer: obs,
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    expect(obs.lastPushed, isNotNull);
    expect(find.byType(ImageViewerPage), findsOneWidget);
  });

  testWidgets('tap is disabled when images is empty (no navigation)', (tester) async {
    final obs = _TestObserver();
    await tester.pumpWidget(
      _wrap(
        const GestureWrappedThumbnail(images: <ImageRef>[], entityId: 'abc'),
        observer: obs,
      ),
    );

    await tester.tap(find.byType(GestureDetector));
    await tester.pumpAndSettle();

    expect(obs.lastPushed, isNull);
    expect(find.byType(ImageViewerPage), findsNothing);
  });
}
