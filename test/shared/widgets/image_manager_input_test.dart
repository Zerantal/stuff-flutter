// test/shared/widgets/image_manager_input_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:stuff/shared/widgets/image_manager_input.dart';
import 'package:stuff/shared/image/image_ref.dart';
import 'package:stuff/core/image_identifier.dart';
import 'package:stuff/services/contracts/image_data_service_interface.dart';
import 'package:stuff/services/contracts/image_picker_service_interface.dart';

import '../../utils/mocks.dart';
import '../../utils/dummies.dart';

void main() {
  late MockIImagePickerService picker;
  late MockIImageDataService store;
  late MockTempSession session;

  setUp(() {
    picker = MockIImagePickerService();
    store = MockIImageDataService();
    session = MockTempSession();
    registerCommonDummies();
  });

  Widget buildTestWidget({
    required List<ImageRef> images,
    required void Function(int) onRemoveAt,
    required void Function(ImageIdentifier, ImageRef) onImagePicked,
    String? placeholderAsset,
  }) {
    return MultiProvider(
      providers: [
        Provider<IImagePickerService>.value(value: picker),
        Provider<IImageDataService>.value(value: store),
      ],
      child: MaterialApp(
        home: Material(
          child: ImageManagerInput(
            session: session,
            images: images,
            onRemoveAt: onRemoveAt,
            onImagePicked: onImagePicked,
            placeholderAsset: placeholderAsset,
          ),
        ),
      ),
    );
  }

  testWidgets('renders thumbnails and add tile', (tester) async {
    final images = [const ImageRef.asset('a.png'), const ImageRef.asset('b.png')];

    await tester.pumpWidget(
      buildTestWidget(images: images, onRemoveAt: (_) {}, onImagePicked: (_, _) {}),
    );

    expect(find.byKey(const Key('img_tile_0')), findsOneWidget);
    expect(find.byKey(const Key('img_tile_1')), findsOneWidget);
    expect(find.byKey(const Key('img_tile_add')), findsOneWidget);
  });

  testWidgets('pressing remove calls onRemoveAt', (tester) async {
    var removed = -1;
    final images = [const ImageRef.asset('a.png')];

    await tester.pumpWidget(
      buildTestWidget(images: images, onRemoveAt: (i) => removed = i, onImagePicked: (_, _) {}),
    );

    await tester.tap(find.byTooltip('Remove'));
    expect(removed, 0);
  });

  testWidgets('pick from gallery yields PickedTemp → onImagePicked called', (tester) async {
    final tmpSrc = File('src.png');
    final tmpDest = File('dest.png');

    when(picker.pickImageFromGallery()).thenAnswer((_) async => tmpSrc);
    when(
      session.importFile(
        any,
        preferredName: anyNamed('preferredName'),
        deleteSource: anyNamed('deleteSource'),
      ),
    ).thenAnswer((_) async => tmpDest);

    ImageIdentifier? pickedId;
    ImageRef? pickedRef;

    await tester.pumpWidget(
      buildTestWidget(
        images: const [],
        onRemoveAt: (_) {},
        onImagePicked: (id, ref) {
          pickedId = id;
          pickedRef = ref;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('img_tile_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick from Gallery'));
    await tester.pumpAndSettle();

    expect(pickedId, isA<TempImageIdentifier>());
    expect((pickedId as TempImageIdentifier).file.path, tmpDest.path);
    expect(pickedRef, isA<FileImageRef>());
  });

  testWidgets('null result from picker (PickCancelled) produces no callback', (tester) async {
    when(picker.pickImageFromGallery()).thenAnswer((_) async => null);

    var called = false;
    await tester.pumpWidget(
      buildTestWidget(images: const [], onRemoveAt: (_) {}, onImagePicked: (_, _) => called = true),
    );

    await tester.tap(find.byKey(const Key('img_tile_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pick from Gallery'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
  });

  testWidgets('SavedGuid with saveImage failure falls back to PickedTemp', (tester) async {
    final tmpSrc = File('src.png');
    final tmpDest = File('dest.png');

    when(picker.pickImageFromCamera()).thenAnswer((_) async => tmpSrc);
    when(
      session.importFile(
        any,
        preferredName: anyNamed('preferredName'),
        deleteSource: anyNamed('deleteSource'),
      ),
    ).thenAnswer((_) async => tmpDest);

    // Simulate store.saveImage throwing
    when(store.saveImage(tmpDest, deleteSource: true)).thenThrow(Exception('disk full'));

    ImageIdentifier? pickedId;
    ImageRef? pickedRef;

    await tester.pumpWidget(
      buildTestWidget(
        images: const [],
        onRemoveAt: (_) {},
        onImagePicked: (id, ref) {
          pickedId = id;
          pickedRef = ref;
        },
      ),
    );

    await tester.tap(find.byKey(const Key('img_tile_add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    // We should get a TempImageIdentifier + FileImageRef (fallback)
    expect(pickedId, isA<TempImageIdentifier>());
    expect((pickedId as TempImageIdentifier).file.path, tmpDest.path);
    expect(pickedRef, isA<FileImageRef>());
  });
}
