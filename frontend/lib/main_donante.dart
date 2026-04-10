// lib/main_donante.dart

import 'package:donapp_android/app_donante.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:donapp_android/providers/theme_provider.dart';
import 'package:donapp_android/widgets/one_signal_check.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // --- INICIO DE MODIFICACIÓN ---
  // 1. Obtenemos las preferencias ANTES de cargar la app
  final prefs = await SharedPreferences.getInstance();
  // 2. Verificamos si la bandera 'hasSeenWelcome' es verdadera. Si no existe, es 'false'.
  final bool hasSeenWelcome = prefs.getBool('hasSeenWelcome') ?? false;
  // --- FIN DE MODIFICACIÓN ---

  // 3. Crear y cargar el proveedor de tema
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme(); // Carga el tema guardado

  // Tu lógica de inicialización existente
  await AuthService.refreshIfNeeded();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  initNotifications();

  // 4. Inyectar el provider y pasar la bandera a AppDonante
  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      // --- MODIFICACIÓN ---
      // Pasamos la bandera a la app principal
      child: AppDonante(hasSeenWelcome: hasSeenWelcome),
    ),
  );
}

// 5. COPIAMOS TU CLASE AuthService
class AuthService {
  // ... (Tu clase AuthService sin cambios) ...
  static Future<void> refreshIfNeeded() async {
    final baseUrl = Uri.parse(ApiConfig.endpoint("api/token/refresh"));
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('authToken');
    final refreshToken = prefs.getString('refreshToken');
    final lastRefreshMillis = prefs.getInt('lastRefresh') ?? 0;

    // No tokens stored → skip
    if (accessToken == null || refreshToken == null) return;

    final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshMillis);
    final now = DateTime.now();

    // If 30 minutes have passed, refresh
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

          print('[Auth] Token successfully refreshed');
        } else {
          print('[Auth] Refresh failed — clearing tokens');
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