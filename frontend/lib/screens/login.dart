// lib/screens/auth/login.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:donapp_android/screens/auth/forgot_password_screen.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/screens/Usuario/otorgar_logro.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:donapp_android/services/session_manager.dart';
import 'package:donapp_android/colours/app_colors.dart';
typedef C = AppColors; // Todavía podemos usarlo para colores primarios

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    // ... (Tu lógica de _login() no necesita cambiar) ...
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(ApiConfig.endpoint("api/token/"));
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _userController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access'];
        final refreshToken = data['refresh'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', accessToken);
        await prefs.setString('refreshToken', refreshToken);

        await SessionManager.setGuestMode(false);

        if (!kIsWeb) {
          await OneSignal.login(_userController.text.trim());
          final playerId = OneSignal.User.pushSubscription.id;
          if (playerId != null) {
            await _actualizarOnesignalId(accessToken, playerId);
          }
        }
        if (!mounted) return;
        final respuesta = await otorgarLogro(accessToken, 'primer_acceso');
        await mostrarDialogoLogro(context, respuesta);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login exitoso")),
        );

        Navigator.pushReplacementNamed(context, '/homedash');
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales inválidas")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enterAsGuest() async {
    // ... (Tu lógica de _enterAsGuest() no necesita cambiar) ...
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await SessionManager.setGuestMode(true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/homedash');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _actualizarOnesignalId(String token, String playerId) async {
    // ... (Tu lógica de _actualizarOnesignalId() no necesita cambiar) ...
    final url = Uri.parse(ApiConfig.endpoint("api/users/actualizar_onesignal/"));
    final body = jsonEncode({"onesignal_player_id": playerId});
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode != 200) {
        debugPrint("Error al actualizar el onesignal_id en el backend.");
      }
    } catch (e) {
      debugPrint("Error en la solicitud HTTP para actualizar onesignal_id: $e");
    }
  }

  // ▼▼▼ FUNCIÓN _decor REPARADA ▼▼▼
  // Ahora toma el Tema actual como argumento
  InputDecoration _decor(ThemeData theme, String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6)), // Color de icono del tema
      suffixIcon: suffix,
      filled: true,
      fillColor: theme.colorScheme.surface, // Color de fondo del tema
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)), // Color de borde del tema
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)), // Color de borde del tema
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2), // Color de foco del tema
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb && MediaQuery.of(context).size.width > 600;
    // ▼▼▼ OBTENEMOS EL TEMA ACTUAL ▼▼▼
    final theme = Theme.of(context);

    final loginForm = AutofillGroup(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            // Usamos un color que funcione en ambos modos
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
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
          const SizedBox(height: 16),
          Text(
            "DonApp",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onBackground, // Color de texto del tema
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _userController,
            autofillHints: const [AutofillHints.username],
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: _decor(theme, 'Nombre de Usuario', Icons.person_outline), // <-- Pasamos el tema
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            obscureText: _obscure,
            enableSuggestions: false,
            autocorrect: false,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            decoration: _decor( // <-- Pasamos el tema
              theme,
              'Contraseña',
              Icons.lock_outline,
              suffix: IconButton(
                tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                    color: theme.colorScheme.onSurface.withOpacity(0.6)), // Color de icono del tema
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            // El ElevatedButton ya está estilizado por el AppTheme (¡bien!)
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 3))
                  : const Text(
                      "Iniciar sesión",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: _isLoading ? null : _enterAsGuest,
            child: Text(
              "Entrar sin registro",
              style: TextStyle(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w600), // Color de texto del tema
            ),
          ),

          const SizedBox(height: 8),
          const Divider(), // El Divider usará el color del tema
          const SizedBox(height: 8),

          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pushNamed(context, '/signup'),
            child: Text(
              "¿No tienes cuenta? Regístrate aquí",
              style: TextStyle(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w600), // Color de texto del tema
            ),
          ),
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
            child: Text(
              "¿Olvidaste tu contraseña?",
              style: TextStyle(
                  color: theme.colorScheme.primary, fontWeight: FontWeight.w600), // Color de texto del tema
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      // backgroundColor: C.background, // <-- ELIMINADO. Deja que el tema lo maneje.
      body: SafeArea(
        // ... (Tu lógica de Web/Móvil no cambia) ...
        child: isWeb
            ? Row(
                 // ... (El layout web también usará los colores del tema) ...
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      // ... (resto del layout web) ...
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(40),
                          child: loginForm,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: loginForm,
                ),
              ),
      ),
    );
  }
}