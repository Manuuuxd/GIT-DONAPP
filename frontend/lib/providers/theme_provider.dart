// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clave para guardar en SharedPreferences
const String _themeKey = 'theme_mode';

class ThemeProvider with ChangeNotifier {
  // Por defecto, usamos el modo del sistema (Cumple CA04)
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Carga el tema guardado al iniciar la app
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    // Lee el índice guardado. Si no hay nada, usa el índice de ThemeMode.system (2)
    final int themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // Cambia el tema y lo guarda
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    // Guarda la preferencia (Cumple CA03)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }
}