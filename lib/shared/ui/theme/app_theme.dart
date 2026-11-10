import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ROCIs Recipes theme, seeded from the app icon: kitchen green with a warm amber accent
/// (same approach as the other ROCIs apps: one brand seed, a dark charcoal base).
class AppTheme {
  static const Color brandGreen = Color(0xFF1F7A4D);
  static const Color brandAmber = Color(0xFFF5A524);

  // Kept for widgets that still read the old palette names.
  static const Color primaryColor = brandGreen;
  static const Color accentColor = brandAmber;
  static const Color errorColor = Color(0xFFEF4444);

  static const Color _darkBase = Color(0xFF101512);
  static const Color _darkSurface = Color(0xFF1A211D);
  static const Color _lightBase = Color(0xFFF6F8F5);

  static ThemeData get lightTheme => createLightTheme(null);
  static ThemeData get darkTheme => createDarkTheme(null, isAmoled: false);

  static ColorScheme _scheme(Brightness brightness) => ColorScheme.fromSeed(
    seedColor: brandGreen,
    brightness: brightness,
  ).copyWith(tertiary: brandAmber, onTertiary: const Color(0xFF2B1C00));

  static ThemeData createLightTheme(ColorScheme? dynamicColorScheme) {
    final scheme = dynamicColorScheme ?? _scheme(Brightness.light);
    return _build(
      scheme.copyWith(surface: _lightBase, surfaceContainerLow: Colors.white),
      ThemeData.light().textTheme,
      cardColor: Colors.white,
      cardBorder: BorderSide(color: scheme.outlineVariant),
      base: _lightBase,
    );
  }

  static ThemeData createDarkTheme(
    ColorScheme? dynamicColorScheme, {
    bool isAmoled = false,
  }) {
    final scheme = dynamicColorScheme ?? _scheme(Brightness.dark);
    final base = isAmoled ? Colors.black : _darkBase;
    final surface = isAmoled ? const Color(0xFF0B0F0C) : _darkSurface;
    return _build(
      scheme.copyWith(surface: base, surfaceContainerLow: surface),
      ThemeData.dark().textTheme,
      cardColor: surface,
      cardBorder: const BorderSide(color: Color(0x1FFFFFFF)),
      base: base,
    );
  }

  static ThemeData _build(
    ColorScheme scheme,
    TextTheme baseText, {
    required Color cardColor,
    required BorderSide cardBorder,
    required Color base,
  }) {
    final text = GoogleFonts.outfitTextTheme(
      baseText,
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final radius = BorderRadius.circular(16);
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: base,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: scheme.onSurface),
        titleTextStyle: GoogleFonts.outfit(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: cardBorder,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.primaryContainer,
        labelStyle: text.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: scheme.tertiary,
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        dividerColor: scheme.outlineVariant,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.tertiary,
          foregroundColor: scheme.onTertiary,
          shape: RoundedRectangleBorder(borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outline),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    );
  }
}
