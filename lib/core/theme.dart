// =============================================================================
// نَذْر - الثيم الداكن
// =============================================================================
import 'package:flutter/material.dart';

class AppTheme {
  // الألوان الأساسية
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceAlt = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);

  // الألوان التفاعلية
  static const Color primary = Color(0xFF1F6FEB);
  static const Color primaryLight = Color(0xFF58A6FF);

  // حالات
  static const Color success = Color(0xFF2EA043);
  static const Color danger = Color(0xFFCF222E);
  static const Color warning = Color(0xFFD29922);
  static const Color purple = Color(0xFF8957E5);
  static const Color cyan = Color(0xFF39C5CF);

  // النصوص
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color textDim = Color(0xFF6E7681);

  // الخطوط
  static const String fontFamily = 'Cairo';

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: fontFamily,
        scaffoldBackgroundColor: background,
        canvasColor: background,
        cardColor: surface,
        dividerColor: border,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: primaryLight,
          unselectedLabelColor: textMuted,
          indicatorColor: primaryLight,
          labelStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryLight,
            side: const BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryLight,
            textStyle: const TextStyle(
              fontFamily: fontFamily,
              fontSize: 13,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceAlt,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryLight),
          ),
          labelStyle: const TextStyle(color: textMuted, fontFamily: fontFamily),
          hintStyle: const TextStyle(color: textDim, fontFamily: fontFamily),
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: border),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: surface,
          titleTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          contentTextStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            color: textPrimary,
          ),
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: surfaceAlt,
          contentTextStyle: TextStyle(
            fontFamily: fontFamily,
            color: textPrimary,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: primaryLight,
          linearTrackColor: surfaceAlt,
        ),
      );
}