import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/colours/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _resetPassword() async {
    setState(() => _loading = true);

    final url = Uri.parse("http://10.0.2.2:8000/api/reset-password/${widget.token}/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"new_password": _passwordController.text.trim()}),
    );

    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.statusCode == 200
          ? "Contraseña cambiada con éxito"
          : "Error al cambiar la contraseña")),
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.background, // <-- Cambio
          elevation: 0,
          title: Text(
            "Agendar Cita",
            style: TextStyle(
              color: AppColors.onBackground, // <-- Cambio
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: IconThemeData(color: AppColors.onBackground), // <-- Cambio
        ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text("Ingresa tu nueva contraseña:"),
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
