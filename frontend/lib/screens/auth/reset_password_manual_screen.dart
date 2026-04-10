import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ResetPasswordManualScreen extends StatefulWidget {
  const ResetPasswordManualScreen({super.key});

  @override
  State<ResetPasswordManualScreen> createState() =>
      _ResetPasswordManualScreenState();
}

class _ResetPasswordManualScreenState extends State<ResetPasswordManualScreen> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    setState(() => _loading = true);

    final token = _tokenController.text.trim();
    final url =
        Uri.parse("http://10.0.2.2:8000/api/users/reset-password/$token/");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"new_password": _passwordController.text.trim()}),
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final accessToken = data['access'];
      final refreshToken = data['refresh'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña cambiada con éxito")),
      );

      // Navegar al home con sesión iniciada
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restablecer Contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
                "Ingresa tu código de recuperación y nueva contraseña:"),
            const SizedBox(height: 16),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: "Código de recuperación",
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Nueva contraseña",
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Cambiar contraseña"),
            ),
          ],
        ),
      ),
    );
  }
}
