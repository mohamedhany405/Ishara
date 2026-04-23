import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central spacing tokens based on an 8dp grid.
class IsharaSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;

  static const EdgeInsets page = EdgeInsets.all(md);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}

/// Central Ishara color and shape tokens.
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
  static const Color mutedLight = Color(0xFF475569);
  static const Color mutedDark = Color(0xFFC5D0E0);

  // Borders
  static const Color lightBorder = Color(0x1F0F172A);
  static const Color darkBorder = Color(0xFF334155);

  // Minimum touch target for accessibility
  static const double minTouchTarget = 48;

  // Radii
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(20));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(999));
  static const BorderRadius inputRadius = BorderRadius.all(Radius.circular(14));

  static List<BoxShadow> cardShadow({required bool dark}) => [
    BoxShadow(
      color: dark ? Colors.black.withOpacity(0.35) : const Color(0x1A0F172A),
      blurRadius: dark ? 18 : 14,
      offset: const Offset(0, 8),
    ),
  ];
}

// Gradient helpers

/// The signature Ishara teal to orange gradient (horizontal).
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

/// Returns a frosted glass style decoration for premium cards and containers.
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
    ...IsharaColors.cardShadow(dark: dark),
    BoxShadow(color: IsharaColors.glowTeal, blurRadius: 40, spreadRadius: -8),
  ],
);

TextTheme _buildTextTheme(TextTheme base, Color foreground, Color muted) {
  final poppins = GoogleFonts.poppinsTextTheme(
    base,
  ).apply(bodyColor: foreground, displayColor: foreground);

  return poppins.copyWith(
    displayLarge: poppins.displayLarge?.copyWith(
      fontSize: 52,
      height: 1.08,
      color: foreground,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
    ),
    displayMedium: poppins.displayMedium?.copyWith(
      fontSize: 44,
      height: 1.1,
      color: foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    displaySmall: poppins.displaySmall?.copyWith(
      fontSize: 36,
      height: 1.1,
      color: foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineLarge: poppins.headlineLarge?.copyWith(
      fontSize: 30,
      height: 1.18,
      color: foreground,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: poppins.headlineMedium?.copyWith(
      fontSize: 26,
      height: 1.2,
      color: foreground,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: poppins.headlineSmall?.copyWith(
      fontSize: 22,
      height: 1.25,
      color: foreground,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: poppins.titleLarge?.copyWith(
      fontSize: 20,
      height: 1.3,
      color: foreground,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    ),
    titleMedium: poppins.titleMedium?.copyWith(
      fontSize: 17,
      height: 1.35,
      color: foreground,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: poppins.titleSmall?.copyWith(
      fontSize: 15,
      height: 1.35,
      color: muted,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: poppins.bodyLarge?.copyWith(
      fontSize: 16,
      height: 1.45,
      color: foreground,
    ),
    bodyMedium: poppins.bodyMedium?.copyWith(
      fontSize: 14,
      height: 1.45,
      color: foreground,
    ),
    bodySmall: poppins.bodySmall?.copyWith(
      fontSize: 12,
      height: 1.4,
      color: muted,
    ),
    labelLarge: poppins.labelLarge?.copyWith(
      fontSize: 14,
      height: 1.2,
      color: foreground,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    labelMedium: poppins.labelMedium?.copyWith(
      fontSize: 12,
      height: 1.25,
      color: muted,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: poppins.labelSmall?.copyWith(
      fontSize: 11,
      height: 1.2,
      color: muted,
      letterSpacing: 0.5,
      fontWeight: FontWeight.w500,
    ),
  );
}

MaterialStateProperty<Color?> _overlayFor(Color color) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.pressed)) {
      return color.withOpacity(0.14);
    }
    if (states.contains(MaterialState.hovered)) {
      return color.withOpacity(0.09);
    }
    if (states.contains(MaterialState.focused)) {
      return color.withOpacity(0.12);
    }
    return null;
  });
}

MaterialStateProperty<BorderSide?> _outlinedSideFor(
  Color color,
  Color disabled,
) {
  return MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.disabled)) {
      return BorderSide(color: disabled);
    }
    return BorderSide(color: color.withOpacity(0.35));
  });
}

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

  final textTheme = _buildTextTheme(
    base.textTheme,
    IsharaColors.lightForeground,
    IsharaColors.mutedLight,
  );

  final disabledBg = IsharaColors.lightForeground.withOpacity(0.12);
  final disabledFg = IsharaColors.lightForeground.withOpacity(0.38);

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    colorScheme: colorScheme,
    scaffoldBackgroundColor: IsharaColors.lightScaffold,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: IsharaColors.lightForeground,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: IsharaColors.lightForeground,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(IsharaColors.minTouchTarget, IsharaColors.minTouchTarget),
        ),
        padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
        overlayColor: _overlayFor(colorScheme.primary),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return disabledFg;
          }
          return IsharaColors.lightForeground;
        }),
      ),
    ),
    cardTheme: CardThemeData(
      color: IsharaColors.lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withOpacity(0.12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        elevation: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return 0;
          if (states.contains(MaterialState.pressed)) return 0;
          return 1.5;
        }),
        shadowColor: MaterialStateProperty.all(
          IsharaColors.tealLight.withOpacity(0.35),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledBg;
          return IsharaColors.tealLight;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return Colors.white;
        }),
        overlayColor: _overlayFor(Colors.white),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledBg;
          return colorScheme.primary;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return colorScheme.onPrimary;
        }),
        overlayColor: _overlayFor(Colors.white),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        side: _outlinedSideFor(colorScheme.primary, colorScheme.outline),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return colorScheme.primary;
        }),
        overlayColor: _overlayFor(colorScheme.primary),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(IsharaColors.minTouchTarget, IsharaColors.minTouchTarget),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return IsharaColors.tealLight;
        }),
        overlayColor: _overlayFor(IsharaColors.tealLight),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: IsharaSpacing.xs,
      minLeadingWidth: 28,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IsharaColors.lightCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: IsharaColors.mutedLight,
      ),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      hintStyle: GoogleFonts.poppins(
        color: IsharaColors.mutedLight,
        fontSize: 14,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      backgroundColor: const Color(0xFF0F172A),
      actionTextColor: IsharaColors.orangeLight,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withOpacity(0.14),
      circularTrackColor: colorScheme.primary.withOpacity(0.12),
      linearMinHeight: 6,
      refreshBackgroundColor: colorScheme.surface,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.titleSmall,
      labelColor: colorScheme.primary,
      unselectedLabelColor: IsharaColors.mutedLight,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
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
      side: BorderSide(color: IsharaColors.tealLight.withOpacity(0.22)),
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: IsharaColors.lightBorder,
      thickness: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
    ),
  );
}

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

  final textTheme = _buildTextTheme(
    base.textTheme,
    IsharaColors.darkForeground,
    IsharaColors.mutedDark,
  );

  final disabledBg = IsharaColors.darkForeground.withOpacity(0.12);
  final disabledFg = IsharaColors.darkForeground.withOpacity(0.38);

  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    colorScheme: colorScheme,
    scaffoldBackgroundColor: IsharaColors.darkScaffold,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: IsharaColors.darkForeground,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: IsharaColors.darkForeground,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(IsharaColors.minTouchTarget, IsharaColors.minTouchTarget),
        ),
        padding: MaterialStateProperty.all(const EdgeInsets.all(10)),
        overlayColor: _overlayFor(colorScheme.primary),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) {
            return disabledFg;
          }
          return IsharaColors.darkForeground;
        }),
      ),
    ),
    cardTheme: CardThemeData(
      color: IsharaColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.cardRadius),
      margin: EdgeInsets.zero,
      shadowColor: Colors.black.withOpacity(0.45),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        elevation: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return 0;
          if (states.contains(MaterialState.pressed)) return 0;
          return 1.5;
        }),
        shadowColor: MaterialStateProperty.all(
          IsharaColors.tealDark.withOpacity(0.45),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledBg;
          return IsharaColors.tealDark;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return Colors.black;
        }),
        overlayColor: _overlayFor(Colors.black),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        backgroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledBg;
          return colorScheme.primary;
        }),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return colorScheme.onPrimary;
        }),
        overlayColor: _overlayFor(Colors.black),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 52)),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
        ),
        side: _outlinedSideFor(colorScheme.primary, colorScheme.outline),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return colorScheme.primary;
        }),
        overlayColor: _overlayFor(colorScheme.primary),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        minimumSize: MaterialStateProperty.all(
          const Size(IsharaColors.minTouchTarget, IsharaColors.minTouchTarget),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        foregroundColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.disabled)) return disabledFg;
          return IsharaColors.tealDark;
        }),
        overlayColor: _overlayFor(IsharaColors.tealDark),
        textStyle: MaterialStateProperty.all(
          GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: IsharaSpacing.xs,
      minLeadingWidth: 28,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: IsharaColors.darkCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      errorStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: colorScheme.error,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: GoogleFonts.poppins(
        fontSize: 14,
        color: IsharaColors.mutedDark,
      ),
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: IsharaColors.inputRadius,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      hintStyle: GoogleFonts.poppins(
        color: IsharaColors.mutedDark,
        fontSize: 14,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      backgroundColor: const Color(0xFF09101D),
      actionTextColor: IsharaColors.orangeDark,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colorScheme.primary,
      linearTrackColor: colorScheme.primary.withOpacity(0.18),
      circularTrackColor: colorScheme.primary.withOpacity(0.16),
      linearMinHeight: 6,
      refreshBackgroundColor: colorScheme.surface,
    ),
    tabBarTheme: TabBarThemeData(
      labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      unselectedLabelStyle: textTheme.titleSmall,
      labelColor: colorScheme.primary,
      unselectedLabelColor: IsharaColors.mutedDark,
      dividerColor: Colors.transparent,
      indicatorSize: TabBarIndicatorSize.tab,
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
      side: BorderSide(color: IsharaColors.tealDark.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: IsharaColors.pillRadius),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: IsharaColors.darkBorder,
      thickness: 1,
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(10),
      ),
      textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
    ),
  );
}
