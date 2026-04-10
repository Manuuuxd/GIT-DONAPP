import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/screens/auth/reset_password_manual_screen.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  Future<void> _sendRecoveryLink() async {
    setState(() => _loading = true);

    final url = Uri.parse("http://10.0.2.2:8000/api/users/request-reset/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": _emailController.text.trim()}),
    );


    print("Status: ${response.statusCode}");
    print("Body: ${response.body}");
    setState(() => _loading = false);

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Si el correo existe, se envió un enlace de recuperación."),
        ),
      );

      // Navegar a la pantalla manual de restablecer contraseña
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ResetPasswordManualScreen(),
        ),
      );

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al solicitar recuperación.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recuperar Cuenta")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              "Ingresa tu correo para recuperar la cuenta:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Correo",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _sendRecoveryLink,
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Enviar enlace"),
            ),
          ],
        ),
      ),
    );
  }
}
