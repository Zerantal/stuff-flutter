// lib/app/theme.dart

import 'package:flutter/material.dart';

import '../shared/widgets/entity_tile_theme.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
    useMaterial3: true,
    extensions: <ThemeExtension<dynamic>>[EntityTileTheme.preset(EntityTileDensity.compact)],
  );
}
