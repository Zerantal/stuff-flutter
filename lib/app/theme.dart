// lib/app/theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/widgets/entity_tile_theme.dart';

/// Design tokens: spacing, radius, elevation
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}

class AppElevation {
  static const double card = 2;
  static const double modal = 6;
}

/// App-wide theme
class AppTheme {
  static ThemeData buildAppTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreen),
      extensions: <ThemeExtension<dynamic>>[EntityTileTheme.preset(EntityTileDensity.compact)],
    );

    return base.copyWith(
      textTheme: GoogleFonts.robotoTextTheme(base.textTheme).copyWith(
        // Medium titles (e.g. list headers, card titles)
        titleMedium: GoogleFonts.robotoTextTheme(base.textTheme).titleMedium?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),

        // Smaller section headers
        headlineSmall: GoogleFonts.robotoTextTheme(base.textTheme).headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),

        // Labels (e.g. LabeledValue, form field labels)
        labelMedium: GoogleFonts.robotoTextTheme(base.textTheme).labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: base.colorScheme.primary,
        ),
      ),

      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: AppElevation.card,
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}
