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
  static const double none = 0; // AppBar, TextField
  static const double low = 1; // Card, Entity tiles, ElevatedButton
  static const double high = 3; // Menus, popups, modals, snackbar, FAB
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
        titleMedium: GoogleFonts.robotoTextTheme(
          base.textTheme,
        ).titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),

        // Smaller section headers
        headlineSmall: GoogleFonts.robotoTextTheme(
          base.textTheme,
        ).headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.bold),

        // Labels (e.g. LabeledValue, form field labels)
        labelMedium: GoogleFonts.robotoTextTheme(base.textTheme).labelMedium?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: base.colorScheme.primary,
        ),
      ),

      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        elevation: AppElevation.low,
        margin: const EdgeInsets.all(AppSpacing.sm),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.md,
        ),
        alignLabelWithHint: true,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.low,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      appBarTheme: const AppBarTheme(
        elevation: AppElevation.low,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.md)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.high,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        elevation: AppElevation.high,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
