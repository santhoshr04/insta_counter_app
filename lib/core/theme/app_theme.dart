import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium dark surfaces: near-black with subtle violet/teal accents.
abstract final class AppTheme {
  static const Color background = Color(0xFF0A0A0C);
  static const Color surface = Color(0xFF14141A);
  static const Color surfaceElevated = Color(0xFF1C1C24);
  static const Color accent = Color(0xFF7C5CFF);
  static const Color accentSecondary = Color(0xFF2EE6C7);
  static const Color outline = Color(0xFF2A2A34);

  static ThemeData darkPremium() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: surface,
        primary: accent,
        secondary: accentSecondary,
        outline: outline,
      ),
      scaffoldBackgroundColor: background,
      canvasColor: background,
    );

    return base.copyWith(
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: Colors.white.withValues(alpha: 0.92),
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: outline, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: accentSecondary,
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: outline,
        thumbColor: accentSecondary,
        overlayColor: accent.withValues(alpha: 0.2),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return accentSecondary;
          return Colors.white38;
        }),
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return accentSecondary.withValues(alpha: 0.35);
          }
          return outline;
        }),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
    );
  }

  /// Alternate “theme” for profile toggle — slightly cooler graphite.
  static ThemeData darkGraphite() {
    final t = darkPremium();
    return t.copyWith(
      colorScheme: t.colorScheme.copyWith(
        surface: const Color(0xFF121218),
        primary: const Color(0xFF5B8CFF),
        secondary: const Color(0xFF5B8CFF),
      ),
      cardTheme: t.cardTheme.copyWith(
        color: const Color(0xFF181820),
      ),
    );
  }

  static BoxDecoration heroGradientBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0D0D12),
          Color(0xFF15101F),
          Color(0xFF0A1214),
        ],
      ),
    );
  }
}
