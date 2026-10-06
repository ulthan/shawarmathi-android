import 'package:flutter/material.dart';

enum ThemeModeOption {
  day('Day Mode', 'Crisp bright aesthetic for daytime shifts', Icons.light_mode_rounded),
  night('Night Mode', 'Deep dark OLED aesthetic for night shifts', Icons.dark_mode_rounded),
  system('System Auto', 'Follow device system preference', Icons.brightness_auto_rounded);

  final String label;
  final String description;
  final IconData icon;

  const ThemeModeOption(this.label, this.description, this.icon);
}

enum DualPaletteType {
  saffronFire(
    'Saffron & Fire',
    'Signature Arabian Shawarmathi',
    Color(0xFFFF6B35), // Fiery Charcoal Orange
    Color(0xFFFFB703), // Arabian Saffron Gold
  );

  final String name;
  final String description;
  final Color primary;
  final Color secondary;

  const DualPaletteType(this.name, this.description, this.primary, this.secondary);
}

class AppTheme {
  // Legacy / Brand Colors (default Saffron & Fire)
  static const Color orangePrimary = Color(0xFFFF6B35);
  static const Color orangePrimaryDark = Color(0xFFCC4E1E);
  static const Color orangeSecondary = Color(0xFFF7931E);
  static const Color accent = Color(0xFFFFD166);

  // Payment Colors
  static const Color cashGreen = Color(0xFF06D6A0);
  static const Color upiBlue = Color(0xFF118AB2);
  static const Color mixedPurple = Color(0xFF8338EC);
  static const Color danger = Color(0xFFEF476F);

  // Dark Surfaces
  static const Color darkBg = Color(0xFF0D0D11);
  static const Color darkSurface = Color(0xFF15161C);
  static const Color darkCard = Color(0xFF1E2028);
  static const Color darkCardElevated = Color(0xFF262833);
  static const Color darkBorder = Color(0xFF2B2E3B);

  // Light Surfaces
  static const Color lightBg = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Helper methods to dynamically query colors based on context brightness
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color scaffoldBg(BuildContext context) {
    return isDark(context) ? darkBg : lightBg;
  }

  static Color surfaceColor(BuildContext context) {
    return isDark(context) ? darkSurface : lightSurface;
  }

  static Color cardColor(BuildContext context) {
    return isDark(context) ? darkCard : lightCard;
  }

  static Color cardElevatedColor(BuildContext context) {
    return isDark(context) ? darkCardElevated : lightCardElevated;
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? darkBorder : lightBorder;
  }

  static Color textPrimary(BuildContext context) {
    return isDark(context) ? Colors.white : const Color(0xFF0F172A);
  }

  static Color textSecondary(BuildContext context) {
    return isDark(context) ? const Color(0xFFB0B7C3) : const Color(0xFF475569);
  }

  static Color textMuted(BuildContext context) {
    return isDark(context) ? const Color(0xFF6B7280) : const Color(0xFF94A3B8);
  }

  static Color primaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color secondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  static LinearGradient dualGradient(
    BuildContext context, {
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    double opacity = 1.0,
  }) {
    final p = primaryColor(context).withValues(alpha: opacity);
    final s = secondaryColor(context).withValues(alpha: opacity);
    return LinearGradient(colors: [p, s], begin: begin, end: end);
  }

  static LinearGradient heroGradient(BuildContext context) {
    final p = primaryColor(context);
    final s = secondaryColor(context);
    if (isDark(context)) {
      return LinearGradient(
        colors: [
          p.withValues(alpha: 0.28),
          s.withValues(alpha: 0.12),
          const Color(0xFF14151C),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [
          p.withValues(alpha: 0.14),
          s.withValues(alpha: 0.08),
          Colors.white,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    if (isDark(context)) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
    }
  }

  // Build ThemeData for Night Mode (Dark)
  static ThemeData buildDarkTheme(DualPaletteType palette) {
    final primary = palette.primary;
    final secondary = palette.secondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      primaryColor: primary,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withValues(alpha: 0.22),
        onPrimaryContainer: Colors.white,
        secondary: secondary,
        onSecondary: Colors.black,
        secondaryContainer: secondary.withValues(alpha: 0.20),
        onSecondaryContainer: Colors.white,
        surface: darkSurface,
        onSurface: Colors.white,
        surfaceContainerHighest: darkCard,
        error: danger,
        onError: Colors.white,
        outline: darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primary.withValues(alpha: 0.22),
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: Colors.white60, size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedCornerShape(16),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: primary.withValues(alpha: 0.25),
        side: const BorderSide(color: darkBorder),
        shape: RoundedCornerShape(10),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        modalBackgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: darkBorder),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
      ),
    );
  }

  // Build ThemeData for Day Mode (Light)
  static ThemeData buildLightTheme(DualPaletteType palette) {
    final primary = palette.primary;
    final secondary = palette.secondary;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primary.withValues(alpha: 0.12),
        onPrimaryContainer: primary,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondary.withValues(alpha: 0.12),
        onSecondaryContainer: secondary,
        surface: lightSurface,
        onSurface: const Color(0xFF0F172A),
        surfaceContainerHighest: lightCardElevated,
        error: danger,
        onError: Colors.white,
        outline: lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primary.withValues(alpha: 0.16),
        elevation: 4,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: primary,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 24);
          }
          return const IconThemeData(color: Color(0xFF64748B), size: 24);
        }),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedCornerShape(16),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightCardElevated,
        selectedColor: primary.withValues(alpha: 0.18),
        side: const BorderSide(color: lightBorder),
        shape: RoundedCornerShape(10),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        modalBackgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: lightBorder),
          foregroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
    );
  }

  // Backward compatible defaults
  static ThemeData get darkTheme => buildDarkTheme(DualPaletteType.saffronFire);
  static ThemeData get lightTheme => buildLightTheme(DualPaletteType.saffronFire);
}

// Helper for rounded borders
RoundedCornerShape roundedCorners(double radius) => RoundedCornerShape(radius);

class RoundedCornerShape extends RoundedRectangleBorder {
  RoundedCornerShape(double radius)
      : super(borderRadius: BorderRadius.circular(radius));
}
