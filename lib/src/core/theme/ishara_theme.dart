import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ──────────────────────────────────────────────────────────────────────────
/// Central Ishara color tokens – mirrors the web design system.
/// ──────────────────────────────────────────────────────────────────────────
class IsharaColors {
  // Brand palette
  static const Color tealLight = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF2DD4BF);
  static const Color orangeLight = Color(0xFFF97316);
  static const Color orangeDark = Color(0xFFFB923C);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color blue = Color(0xFF0EA5E9);

  // Accent used for glows / shimmer highlights
  static const Color glowTeal = Color(0x3314B8A6);
  static const Color glowOrange = Color(0x33F97316);

  // Light surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightScaffold = Color(0xFFEFF1F5);
  static const Color lightCard = Colors.white;

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkScaffold = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkCardHover = Color(0xFF273548);

  // Text
  static const Color lightForeground = Color(0xFF0F172A);
  static const Color darkForeground = Color(0xFFF1F5F9);
  static const Color mutedLight = Color(0xFF64748B);
  static const Color mutedDark = Color(0xFF94A3B8);

  // Borders
  static const Color lightBorder = Color(0x1A000000);
  static const Color darkBorder = Color(0xFF334155);

  // Radii
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(14));
}

// ─────────────────────────────────────────────────────────────────────────────
// Gradient helpers
// ─────────────────────────────────────────────────────────────────────────────

/// The signature Ishara teal → orange gradient (horizontal).
LinearGradient isharaHorizontalGradient({bool dark = false}) => LinearGradient(
  colors: [
    dark ? IsharaColors.tealDark : IsharaColors.tealLight,
    dark ? IsharaColors.orangeDark : IsharaColors.orangeLight,
  ],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

/// Diagonal variant used on hero banners and cards.
LinearGradient isharaDiagonalGradient({bool dark = false}) => LinearGradient(
  colors: [
    dark ? IsharaColors.tealDark : IsharaColors.tealLight,
    dark ? IsharaColors.orangeDark : IsharaColors.orangeLight,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// Returns a `BoxDecoration` with a frosted-glass / glassmorphism look.
/// Use for cards, bottom sheets, and floating containers.
BoxDecoration glassmorphismDecoration({required bool dark}) => BoxDecoration(
  color:
      dark
          ? IsharaColors.darkCard.withOpacity(0.72)
          : IsharaColors.lightCard.withOpacity(0.72),
  borderRadius: IsharaColors.cardRadius,
  border: Border.all(
    color:
        dark
            ? IsharaColors.tealDark.withOpacity(0.18)
            : IsharaColors.tealLight.withOpacity(0.18),
    width: 1.2,
  ),
  boxShadow: [
    BoxShadow(
      color: dark ? Colors.black54 : Colors.black12,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: dark ? IsharaColors.glowTeal : IsharaColors.glowTeal,
      blurRadius: 40,
      spreadRadius: -8,
    ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
// Text theme built on Google Fonts Poppins
// ─────────────────────────────────────────────────────────────────────────────
TextTheme _buildTextTheme(TextTheme base, Color foreground, Color muted) {
  final poppins = GoogleFonts.poppinsTextTheme(base);
  return poppins.copyWith(
    displayLarge: poppins.displayLarge?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
    ),
    displayMedium: poppins.displayMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    displaySmall: poppins.displaySmall?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: poppins.headlineLarge?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: poppins.headlineMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: poppins.headlineSmall?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: poppins.titleLarge?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleMedium: poppins.titleMedium?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w500,
    ),
    titleSmall: poppins.titleSmall?.copyWith(
      color: muted,
      fontWeight: FontWeight.w500,
    ),
    bodyLarge: poppins.bodyLarge?.copyWith(color: foreground),
    bodyMedium: poppins.bodyMedium?.copyWith(color: foreground),
    bodySmall: poppins.bodySmall?.copyWith(color: muted),
    labelLarge: poppins.labelLarge?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    labelMedium: poppins.labelMedium?.copyWith(color: muted),
    labelSmall: poppins.labelSmall?.copyWith(color: muted, letterSpacing: 1.0),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Light theme
// ─────────────────────────────────────────────────────────────────────────────
ThemeData buildIsharaLightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: IsharaColors.tealLight,
    brightness: Brightness.light,
    primary: IsharaColors.tealLight,
    secondary: IsharaColors.orangeLight,
    surface: IsharaColors.lightCard,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: IsharaColors.lightForeground,
    outline: IsharaColors.lightBorder,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: IsharaColors.lightScaffold,
    textTheme: _buildTextTheme(
      base.textTheme,
      IsharaColors.lightForeground,
      IsharaColors.mutedLight,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: IsharaColors.lightForeground,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: IsharaColors.lightForeground,
      ),
    ),
    cardTheme: CardThemeData(
      color: IsharaColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: IsharaColors.tealLight,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: IsharaColors.tealLight,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IsharaColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: IsharaColors.lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: IsharaColors.lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: IsharaColors.tealLight, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: IsharaColors.mutedLight,
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: IsharaColors.tealLight,
      unselectedItemColor: IsharaColors.mutedLight,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: IsharaColors.lightCard,
      selectedColor: IsharaColors.tealLight.withOpacity(0.12),
    ),
    dividerTheme: const DividerThemeData(
      color: IsharaColors.lightBorder,
      thickness: 1,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Dark theme
// ─────────────────────────────────────────────────────────────────────────────
ThemeData buildIsharaDarkTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final colorScheme = ColorScheme.fromSeed(
    seedColor: IsharaColors.tealDark,
    brightness: Brightness.dark,
    primary: IsharaColors.tealDark,
    secondary: IsharaColors.orangeDark,
    surface: IsharaColors.darkCard,
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: IsharaColors.darkForeground,
    outline: IsharaColors.darkBorder,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: IsharaColors.darkScaffold,
    textTheme: _buildTextTheme(
      base.textTheme,
      IsharaColors.darkForeground,
      IsharaColors.mutedDark,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: IsharaColors.darkForeground,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: IsharaColors.darkForeground,
      ),
    ),
    cardTheme: CardThemeData(
      color: IsharaColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: IsharaColors.tealDark,
        foregroundColor: Colors.black,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: IsharaColors.tealDark,
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IsharaColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: const BorderSide(color: IsharaColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: const BorderSide(color: IsharaColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: const BorderSide(color: IsharaColors.tealDark, width: 2),
      ),
      hintStyle: GoogleFonts.poppins(
        color: IsharaColors.mutedDark,
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: IsharaColors.tealDark,
      unselectedItemColor: IsharaColors.mutedDark,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      backgroundColor: Color(0xFF070E1A),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: IsharaColors.darkCard,
      selectedColor: IsharaColors.tealDark.withOpacity(0.2),
    ),
    dividerTheme: const DividerThemeData(
      color: IsharaColors.darkBorder,
      thickness: 1,
    ),
  );
}
