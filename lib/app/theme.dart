// lib/app/theme.dart
// coverage:ignore-file

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
  static const double none = 0; // Scaffolds, background
  static const double low = 1; // Cards, TextFields
  static const double med = 3; // Menus, small sheets, dropdowns
  static const double high = 6; // Snackbars, modals, popups
  static const double fab = 8; // FloatingActionButton, prominent
}

/// App-wide theme
class AppTheme {
  static ThemeData buildAppTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
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

      menuTheme: MenuThemeData(
        style: MenuStyle(
          elevation: const WidgetStatePropertyAll(AppElevation.med),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
          ),
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
        floatingLabelStyle: GoogleFonts.roboto(
          color: base.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: base.textTheme.bodyMedium?.copyWith(color: base.colorScheme.onSurfaceVariant),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.low,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      appBarTheme: AppBarTheme(
        elevation: AppElevation.low,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(AppRadius.md)),
        ),
        titleTextStyle: GoogleFonts.roboto(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onPrimary,
        ),
        backgroundColor: base.colorScheme.primary,
        foregroundColor: base.colorScheme.onPrimary,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppElevation.fab,
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
        backgroundColor: base.colorScheme.inverseSurface,
        contentTextStyle: GoogleFonts.roboto(color: base.colorScheme.onInverseSurface),
      ),
    );
  }
}
