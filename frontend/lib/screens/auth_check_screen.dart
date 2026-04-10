// lib/screens/auth_check_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:donapp_android/colours/app_colors.dart'; // Para los colores

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  _AuthCheckScreenState createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  @override
  void initState() {
    super.initState();
    // Inicia el chequeo de autenticación tan pronto como la pantalla se construye
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Espera un momento para que se muestre el logo (splash screen)
    await Future.delayed(const Duration(milliseconds: 1500));

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('authToken');

    bool isLoggedIn = false;
    if (token != null) {
      try {
        // Revisa si el token NO está expirado
        if (!JwtDecoder.isExpired(token)) {
          isLoggedIn = true;
        } else {
          // El token existe pero está expirado, lo limpiamos
          await prefs.remove('authToken');
          await prefs.remove('refreshToken');
        }
      } catch (e) {
        // El token estaba corrupto, lo limpiamos
        await prefs.remove('authToken');
        await prefs.remove('refreshToken');
      }
    }

    // Redirige a la pantalla correcta.
    // Usamos 'pushReplacementNamed' para que el usuario no pueda "volver"
    // a esta pantalla de carga.
    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Esta es tu pantalla de carga.
    // Puedes poner tu logo aquí.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon.png', // Asegúrate de que esta ruta sea correcta
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}