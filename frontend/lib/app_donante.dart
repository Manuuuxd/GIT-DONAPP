// lib/app_donante.dart

import 'package:donapp_android/screens/WebDonante/Donante_home_screen.dart';
import 'package:donapp_android/screens/dashboard_web.dart';
import 'package:flutter/material.dart';
// Importamos todas las pantallas de Donante
import 'package:donapp_android/screens/homeroot.dart';
import 'package:donapp_android/screens/login.dart';
import 'package:donapp_android/screens/politica_privacidad_screen.dart';
import 'package:donapp_android/screens/signup_screen.dart';
import 'package:donapp_android/screens/trivia/pantallaSeleccion.dart';
import 'package:donapp_android/screens/trivia/question_screen.dart';
import 'package:donapp_android/screens/Simulacion/sim.dart';
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:donapp_android/screens/schedule/HistoryScreen.dart';
import 'package:donapp_android/screens/Usuario/logros.dart';
import 'package:donapp_android/screens/CheckAuthScreen.dart';
// Importamos la clave del navegador global
import 'package:flutter/material.dart';

import 'package:donapp_android/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:donapp_android/providers/theme_provider.dart';
import 'package:donapp_android/colours/app_theme.dart';

// --- INICIO DE MODIFICACIÓN ---
// 1. Importar la nueva pantalla de bienvenida
import 'package:donapp_android/screens/welcome_screen.dart';
// --- FIN DE MODIFICACIÓN ---

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class AppDonante extends StatelessWidget {
  // --- INICIO DE MODIFICACIÓN ---
  // 2. Añadir la bandera al widget
  final bool hasSeenWelcome;

  // 3. Actualizar el constructor
  const AppDonante({
    super.key,
    required this.hasSeenWelcome,
  });
  // --- FIN DE MODIFICACIÓN ---

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Donapp',
      debugShowCheckedModeBanner: false,


      // 4. Aplicar los temas
      theme: AppTheme.lightTheme,       // Tu tema claro
      darkTheme: AppTheme.darkTheme,     // Tu tema oscuro
      themeMode: themeProvider.themeMode,

      // --- INICIO DE MODIFICACIÓN ---
      // 5. Decidir la pantalla 'home' basada en la bandera
      // Si ya la ha visto, vamos al CheckAuthScreen.
      // Si no la ha visto, vamos al WelcomeScreen.
      home: hasSeenWelcome
          ? const CheckAuthScreen()
          : const WelcomeScreen(),
      // --- FIN DE MODIFICACIÓN ---

      routes: {
        '/home': (_) => const HomeRoot(),
        '/homedash': (_) => const DashboardRoot(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/trivia': (_) => const NivelIntroScreen(),
        '/politica': (_) => const PoliticaPrivacidadScreen(showContinue: true),
        '/filtro': (_) => const FiltroUsuariosScreen(),
        '/history': (_) => const HistoryScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/jenny': (context) => const JennyGamePage(),
        '/logros': (_) => const LogrosScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/question') {
          final dificultad = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => QuestionScreen(dificultad: dificultad),
          );
        }
        if (settings.name == '/map') {
          final campaignData = settings.arguments as dynamic;
          debugPrint("Recibido en onGenerateRoute /map: $campaignData");
          return MaterialPageRoute(
            builder: (context) => MapScreen(
              focusCampania: campaignData,
            ),
          );
        }
        return null;
      },
    );
  }
}