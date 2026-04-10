// lib/colours/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart'; // Importa tus colores base

class AppTheme {
  
  // --- TEMA CLARO (LIGHT) ---
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.customBlue,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData( // <-- CORRECCIÓN: Era CardTheme
      elevation: 2,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: AppColors.background,
      surface: AppColors.surface,
      onBackground: AppColors.onBackground,
      onSurface: AppColors.onBackground,
    ),
  );

  // --- TEMA OSCURO (DARK) ---
  // (Cumple con CA02 y CA05: coherencia de colores oscuros)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: const Color(0xFF121212), // Fondo oscuro estándar
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1F1F1F), // AppBar un poco más clara
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData( // <-- CORRECCIÓN: Era CardTheme
      elevation: 1,
      color: const Color(0xFF1E1E1E), // Color de tarjeta estándar
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary, // El primario resalta bien
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // Define el esquema de colores oscuros
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onBackground: Colors.white, // Texto sobre fondo
      onSurface: Colors.white, // Texto sobre tarjetas
    ),
  );
}