// lib/screens/welcome_screen.dart

import 'package:donapp_android/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = false;

  /// Marca la pantalla de bienvenida como vista y navega.
  Future<void> _setWelcomeFlagAndNavigate(Function navigationLogic) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // 1. Marcar la bandera en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasSeenWelcome', true);

      // 2. Ejecutar la lógica de navegación (Login o Guest)
      if (mounted) {
        await navigationLogic(context);
      }
    } catch (e) {
      // Manejar error si es necesario
      debugPrint("Error al guardar la bandera de bienvenida: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    // No necesitamos poner _isLoading = false si la navegación es exitosa,
    // ya que la pantalla será reemplazada.
  }

  /// Navega a la pantalla de Login
  void _onLoginPressed(BuildContext context) {
    _setWelcomeFlagAndNavigate((navContext) {
      Navigator.pushReplacementNamed(navContext, '/login');
    });
  }

  /// Configura el modo invitado y navega a Home
  Future<void> _onGuestPressed(BuildContext context) async {
    await _setWelcomeFlagAndNavigate((navContext) async {
      await SessionManager.setGuestMode(true);
      if (mounted) {
        Navigator.pushReplacementNamed(navContext, '/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Icono/Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Center(
                  child: Image.asset(
                    'assets/images/icon.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. Título
              Text(
                "¡Bienvenido a DonApp!",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 16),

              // 3. Descripción
              Text(
                "Una app nacida para conectar donantes y facilitar el aprendizaje sobre la donación de sangre.",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: size.height * 0.1), // Espacio flexible

              // 4. Botón de Iniciar Sesión
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _onLoginPressed(context),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3))
                      : const Text(
                          "Iniciar sesión",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Botón de Entrar sin registro
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _isLoading ? null : () => _onGuestPressed(context),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: const Text(
                    "Entrar sin registro",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}