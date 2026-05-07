import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppShadows {
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get float => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];
  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.35),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get billingGlow => [
        BoxShadow(
          color: AppColors.billingAccent.withValues(alpha: 0.25),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
  static List<BoxShadow> get glow => card;
}

class AppTextStyles {
  static TextStyle display({Color color = AppColors.slate900, double size = 40}) =>
      AppTheme.serif(size: size, weight: FontWeight.w800, color: color);
  static TextStyle headline({Color color = AppColors.slate900, double size = 28}) =>
      AppTheme.serif(size: size, weight: FontWeight.w700, color: color);
  static TextStyle title({Color color = AppColors.slate900, double size = 20}) =>
      AppTheme.serif(size: size, weight: FontWeight.w700, color: color);
  static TextStyle label({Color color = AppColors.slate700, double size = 14}) =>
      AppTheme.sans(size: size, weight: FontWeight.w600, color: color);
  static TextStyle body({Color color = AppColors.slate500, double size = 13}) =>
      AppTheme.sans(size: size, color: color);
  static TextStyle overline({Color color = AppColors.slate400, double size = 10}) =>
      AppTheme.sans(size: size, weight: FontWeight.w700, color: color, letterSpacing: 1.5);
  static TextStyle numeric({Color color = AppColors.slate900, double size = 24}) =>
      AppTheme.sans(size: size, weight: FontWeight.w900, color: color);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.ivory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.slate900,
        surface: AppColors.white,
        onSurface: AppColors.slate900,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.slate900),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.slate100),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.slate900,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.slate900,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }
}
