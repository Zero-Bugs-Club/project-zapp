import 'package:flutter/material.dart';

/// Vivid orange and white theme palette for Project Zapp Authentication & General Branding.
const Color zappOrange = Color(0xFFE87532);
const Color zappCream = Color(0xFFFFFAF5);
const Color zappCharcoal = Color(0xFF29251F);
const Color zappMuted = Color(0xFF81786F);
const Color zappBorder = Color(0xFFE8DED4);
const Color zappOrangeLight = Color(0xFFFFF2E8);

/// Apple Design System tokens inspired by Apple Human Interface Guidelines (design.md).
const Color kAppleBlue = Color(0xFF0071E3);
const Color kAppleBlueDark = Color(0xFF0055C6);
const Color kAppleTextPrimary = Color(0xFF1D1D1F);
const Color kAppleTextSecondary = Color(0xFF6E6E73);
const Color kAppleTextTertiary = Color(0xFFAEAEB2);
const Color kAppleBackground = Color(0xFFFFFFFF);
const Color kAppleSurface = Color(0xFFF5F5F7);
const Color kAppleBorder = Color(0xFFD2D2D7);
const Color kAppleBorderLight = Color(0xFFE5E5EA);
const Color kAppleSuccess = Color(0xFF34C759);
const Color kAppleError = Color(0xFFFF3B30);

/// Shared unified theme matching design.md and authentication flows.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: zappCream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: zappOrange,
    primary: zappOrange,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSurface: zappCharcoal,
  ),
  fontFamily: '-apple-system',
  fontFamilyFallback: const [
    'BlinkMacSystemFont',
    'SF Pro Display',
    'SF Pro Text',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ],
  appBarTheme: const AppBarTheme(
    backgroundColor: zappCream,
    foregroundColor: zappCharcoal,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: zappCharcoal,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: zappOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: zappOrange,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: zappBorder),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    labelStyle: const TextStyle(color: zappMuted),
    hintStyle: const TextStyle(color: zappMuted),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: zappBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: zappBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: zappOrange, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.8),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: Colors.white,
    indicatorColor: zappOrangeLight,
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: zappOrange);
      }
      return const IconThemeData(color: zappMuted);
    }),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const TextStyle(
          color: zappOrange,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        );
      }
      return const TextStyle(
        color: zappMuted,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      );
    }),
  ),
);
