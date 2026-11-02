import 'package:flutter/material.dart';

// ── Change this to your server IP / deployed URL ──────────────────────────
const String kBaseUrl = 'http://192.0.0.100:8000';

// ── Severity colours ────────────────────────────────────────────────────────
const kCritical = Color(0xFFC46A7A);
const kHigh     = Color(0xFFC99A53);
const kMedium   = Color(0xFFA88B2E);
const kLow      = Color(0xFF6E9C82);

Color severityColor(String s) {
  switch (s.toUpperCase()) {
    case 'CRITICAL': return kCritical;
    case 'HIGH':     return kHigh;
    case 'MEDIUM':   return kMedium;
    default:         return kLow;
  }
}

// ── Theme ────────────────────────────────────────────────────────────────────
const _violet = Color(0xFF6C63B5);
const _ink    = Color(0xFF1F2333);
const _cream  = Color(0xFFF7F4EE);

ThemeData get revaTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _violet,
        brightness: Brightness.light,
        background: _cream,
        surface: Colors.white,
        primary: _violet,
        onPrimary: Colors.white,
        onBackground: _ink,
        onSurface: _ink,
      ),
      scaffoldBackgroundColor: _cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE4DFD3)),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _violet,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32, fontWeight: FontWeight.w800,
          color: _ink, letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700,
          color: _ink, letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w700, color: _ink,
        ),
        titleMedium: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w600, color: _ink,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: _ink, height: 1.5),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF565B73), height: 1.4),
        bodySmall: TextStyle(fontSize: 11, color: Color(0xFF8C8FA3)),
        labelLarge: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700,
          letterSpacing: 0.6, color: _ink,
        ),
      ),
    );
