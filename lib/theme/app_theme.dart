import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color primaryEmerald = Color(0xFF059669);
  static const Color primaryDark = Color(0xFF047857);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color surfaceCard = Color(0xFF1E293B);
  static const Color backgroundLight = Color(0xFFF8FAFC);

  // Vitals Metric Tokens
  static const Color hrRed = Color(0xFFFF5252);
  static const Color spO2Blue = Color(0xFF448AFF);
  static const Color spO2Cyan = Color(0xFF00E5FF);
  static const Color statusGreen = Color(0xFF00E676);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        primary: primaryEmerald,
        secondary: spO2Blue,
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF1E293B)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: slateDark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: primaryEmerald,
        primary: primaryEmerald,
        surface: surfaceCard,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: surfaceCard,
      ),
    );
  }
}
