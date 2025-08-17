// test/features/location/widgets/skeleton_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stuff/features/location/widgets/skeleton_tile.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('SkeletonTile builds without exceptions', (tester) async {
    await tester.pumpWidget(wrap(const SkeletonTile()));
    expect(find.byType(SkeletonTile), findsOneWidget);
  });
}
