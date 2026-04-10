// lib/main_admin.dart

import 'package:flutter/material.dart';
import 'package:donapp_android/app_admin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; // <-- 1. Importar Provider
import 'package:donapp_android/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Crear y cargar el proveedor de tema
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme(); // Carga el tema guardado
  
  // El Admin también necesita refrescar su token
  await AuthService.refreshIfNeeded();

  // El Admin también necesita Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // NO INCLUIMOS initNotifications() aquí

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const AppAdmin(),
    ),
  );
}

// COPIAMOS LA CLASE AuthService aquí también
// (Idealmente, esto debería ir en su propio archivo 'services/auth_service.dart'
// para no duplicar código, pero sigo la estructura de tu main.dart)
class AuthService {
  static Future<void> refreshIfNeeded() async {
    final baseUrl = Uri.parse(ApiConfig.endpoint("api/token/refresh"));
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('authToken');
    final refreshToken = prefs.getString('refreshToken');
    final lastRefreshMillis = prefs.getInt('lastRefresh') ?? 0;

    if (accessToken == null || refreshToken == null) return;

    final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshMillis);
    final now = DateTime.now();

    if (now.difference(lastRefresh) > const Duration(minutes: 30)) {
      try {
        final response = await http.post(
          baseUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final newAccessToken = data['access'];
          await prefs.setString('authToken', newAccessToken);
          await prefs.setInt('lastRefresh', now.millisecondsSinceEpoch);
        } else {
          await prefs.remove('authToken');
          await prefs.remove('refreshToken');
          await prefs.remove('lastRefresh');
        }
      } catch (e) {
        print('[Auth] Error while refreshing token: $e');
      }
    }
  }
}