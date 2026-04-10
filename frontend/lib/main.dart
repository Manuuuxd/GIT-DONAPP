//import 'package:donapp_android/screens/home_screen.dart';
import 'package:donapp_android/screens/homeroot.dart';
import 'package:donapp_android/screens/login.dart';
import 'package:donapp_android/screens/politica_privacidad_screen.dart';
import 'package:donapp_android/screens/signup_screen.dart';
import 'package:donapp_android/screens/trivia/pantallaSeleccion.dart';
import 'package:donapp_android/screens/trivia/question_screen.dart';
import 'package:donapp_android/screens/Simulacion/sim.dart';
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/widgets/one_signal_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:donapp_android/screens/schedule/HistoryScreen.dart';
import 'package:donapp_android/screens/Usuario/logros.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'CONFIG/api_config.dart';
import 'screens/CheckAuthScreen.dart';

import 'firebase_options.dart';

import 'package:flutter/foundation.dart' show kIsWeb;


class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget web;

  const ResponsiveLayout({super.key, required this.mobile, required this.web});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) return web;
          return mobile;
        },
      );
    }
    return mobile;
  }
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();


void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.refreshIfNeeded();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  initNotifications();

  runApp(const MyApp());

}
class AuthService {


  /// Checks if the access token is older than 30 minutes and refreshes it if needed.
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Donapp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CheckAuthScreen(),
      routes: {
        '/home': (_) => const HomeRoot(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/trivia': (_) => const NivelIntroScreen(),
        '/politica': (_) => const PoliticaPrivacidadScreen(showContinue: true),
        '/filtro': (_) => const FiltroUsuariosScreen(),
        '/history': (_) => const HistoryScreen(),
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
