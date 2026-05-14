import 'package:flutter/material.dart';

class ThemeApp {
  static ThemeData lightThemeData = themeData(lightColorScheme);

  static ThemeData darkThemeData = themeData(darkColorScheme);

  static ThemeData themeData(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      cardTheme: const CardThemeData(color: Colors.black38, elevation: 10),
      dialogTheme: DialogThemeData(backgroundColor: colorScheme.onPrimary),
    );
  }

  static ColorScheme lightColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: Color(0xFF0082C9),
  );

  static ColorScheme darkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: Color(0xFF0082C9),
  );
}
