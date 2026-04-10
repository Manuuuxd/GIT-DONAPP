// lib/screens/admin/admin_login_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:donapp_android/screens/admin/admin_dashboard_screen.dart';
import 'package:donapp_android/colours/app_colors.dart';
typedef C = AppColors;

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // ... (Tu lógica de _handleLogin() no necesita cambiar) ...
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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

        final Map<String, dynamic> decodedToken = JwtDecoder.decode(accessToken);
        final bool isAdmin = decodedToken['is_admin'] ?? false;

        if (isAdmin) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', accessToken);
          await prefs.setString('refreshToken', refreshToken);

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else {
          setState(() {
            _errorMessage = "Acceso denegado. No tiene permisos de administrador.";
          });
        }
      } else {
        setState(() {
          _errorMessage = "Credenciales inválidas. Intente de nuevo.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Error de conexión: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    // ▼▼▼ OBTENEMOS EL TEMA ACTUAL ▼▼▼
    final theme = Theme.of(context);

    final loginForm = AutofillGroup(
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center, // Quitamos esto para el bug de overflow
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Espaciador
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
            "DonApp Admin",
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
            keyboardType: TextInputType.text,
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
            onSubmitted: (_) => _handleLogin(),
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 48,
            // El ElevatedButton ya está estilizado por el AppTheme
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
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
          const SizedBox(height: 40), // Espaciador
        ],
      ),
    );

    return Scaffold(
      // backgroundColor: C.background, // <-- ELIMINADO.
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: loginForm,
            ),
          ),
        ),
      ),
    );
  }
}