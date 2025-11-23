import 'package:flutter/material.dart';

class AppTheme {
  // Default Colors
  static Color background = Colors.black;
  static Color text = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color hover = Color(0xFF424242);
  static Color primary = Colors.blue;
  
  // Update colors dynamically
  static void updateColors({
    Color? newBackground,
    Color? newPrimary,
  }) {
    if (newBackground != null) background = newBackground;
    if (newPrimary != null) primary = newPrimary;
  }
  
  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: text,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
        titleLarge: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: text,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFF1A1A1A),
        hintStyle: TextStyle(color: textSecondary),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
  
  // Reusable Node Style
  static BoxDecoration nodeDecoration({
    required bool isDragged,
    Color? customColor,
  }) {
    return BoxDecoration(
      color: isDragged 
          ? (customColor ?? primary).withOpacity(0.8)
          : (customColor ?? primary).withOpacity(0.3),
      shape: BoxShape.circle,
      border: Border.all(
        color: isDragged 
            ? (customColor ?? primary)
            : (customColor ?? primary).withOpacity(0.6),
        width: isDragged ? 3 : 2,
      ),
    );
  }
  
  // Reusable Text Style
  static const TextStyle nodeTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );
}