import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscure = true;

  // Preferencias de contacto
  final Map<String, String> opciones = {
    'push': 'Notificación Push',
    'whatsapp': 'WhatsApp',
    'correo': 'Correo Electrónico',
  };
  final Set<String> seleccionadas = {};

  // Sexo biológico (M / F)
  String? sexoSeleccionado;

  @override
  void dispose() {
    userController.dispose();
    emailController.dispose();
    passwordController.dispose();
    whatsappController.dispose();
    super.dispose();
  }

  bool validarWhatsApp(String numero) {
    final regex = RegExp(r'^\+\d{8,15}$');
    return regex.hasMatch(numero);
  }

  bool validarEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  Future<void> registerUser(
    String username,
    String email,
    String password,
    List<String> preferencias,
    String sexo, {
    String? telefono,
  }) async {
    setState(() => _loading = true);
    final url = Uri.parse(ApiConfig.endpoint("api/users/register/"));

    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'preferencias_notificacion': preferencias, // mismos nombres del backend
      'sexo': sexo,
    };
    if (telefono != null) body['telefono'] = telefono;

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 500) {
        // Login automático
        final loginUrl = Uri.parse(ApiConfig.endpoint("api/token/"));
        final loginResponse = await http.post(
          loginUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'username': username, 'password': password}),
        );

        if (loginResponse.statusCode == 200) {
          final data = jsonDecode(loginResponse.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', data['access']);
          await prefs.setString('refreshToken', data['refresh']);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/homedash');
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro ok, pero falló el login automático')),
          );
        }
      } else {
        String error = 'Error al registrar usuario';
        try {
          final data = jsonDecode(response.body);
          error = data.toString();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSubmit() {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, corrige los campos en rojo.')),
      );
      return;
    }

    if (seleccionadas.isEmpty || sexoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona sexo biológico y al menos una preferencia.')),
      );
      return;
    }

    final username = userController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final whatsapp = whatsappController.text.trim();

    if (seleccionadas.contains('whatsapp')) {
      if (whatsapp.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ingresa tu número de WhatsApp.')));
        return;
      }
      if (!validarWhatsApp(whatsapp)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp inválido. Usa formato +569XXXXXXXX')),
        );
        return;
      }
    }

    registerUser(
      username,
      email,
      password,
      seleccionadas.toList(),
      sexoSeleccionado!, // 'M' o 'F'
      telefono: seleccionadas.contains('whatsapp') ? whatsapp : null,
    );
  }

  // ---------- UI helpers ----------
  InputDecoration _filled(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }

  Widget _segmentedRadio({
    required String value,
    required String groupValue,
    required String label,
    required IconData icon,
    required void Function() onTap,
  }) {
    final selected = value == groupValue;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.redAccent : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.redAccent : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: selected
              ? [BoxShadow(blurRadius: 8, offset: const Offset(0, 4), color: Colors.redAccent.withOpacity(0.16))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : Colors.black54),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: selected ? Colors.white : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                // Header con ícono
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/images/icon.png', fit: BoxFit.cover, filterQuality: FilterQuality.high),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Crear Cuenta',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
                ),
                const SizedBox(height: 16),

                // Card principal
                Card(
                  elevation: 3.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Usuario
                          TextFormField(
                            controller: userController,
                            textInputAction: TextInputAction.next,
                            decoration: _filled('Nombre de Usuario'),
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? 'Ingresa un nombre de usuario' : null,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          TextFormField(
                            controller: emailController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _filled('Correo electrónico', hint: 'nombre@ejemplo.com'),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Ingresa tu correo';
                              if (!validarEmail(value)) return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Password
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscure,
                            decoration: _filled('Contraseña').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              final value = v ?? '';
                              if (value.isEmpty) return 'Ingresa tu contraseña';
                              if (value.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Sexo biológico (necesario para la donación, no refleja tu género)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // RADIO responsive (salta de línea si no cabe)
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final spacing = 10.0;
                              final itemWidth = (constraints.maxWidth - spacing) / 2;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _segmentedRadio(
                                      value: 'M',
                                      groupValue: sexoSeleccionado ?? '',
                                      label: 'Masculino',
                                      icon: Icons.male,
                                      onTap: () => setState(() => sexoSeleccionado = 'M'),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _segmentedRadio(
                                      value: 'F',
                                      groupValue: sexoSeleccionado ?? '',
                                      label: 'Femenino',
                                      icon: Icons.female,
                                      onTap: () => setState(() => sexoSeleccionado = 'F'),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 18),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '¿Cómo te gustaría que nos contactáramos contigo?',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Chips de preferencias (multi-selección)
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: opciones.keys.map((key) {
                              final selected = seleccionadas.contains(key);
                              return ChoiceChip(
                                label: Text(opciones[key]!),
                                selected: selected,
                                onSelected: (val) {
                                  setState(() {
                                    if (val) {
                                      seleccionadas.add(key);
                                    } else {
                                      seleccionadas.remove(key);
                                    }
                                  });
                                },
                                selectedColor: red,
                                backgroundColor: Colors.grey.shade100,
                                elevation: 0,
                                pressElevation: 0,
                                labelStyle: TextStyle(
                                  color: selected ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 12),

                          if (seleccionadas.contains('whatsapp'))
                            TextFormField(
                              controller: whatsappController,
                              keyboardType: TextInputType.phone,
                              decoration: _filled('Número de WhatsApp', hint: '+569XXXXXXXX'),
                              validator: (v) {
                                if (!seleccionadas.contains('whatsapp')) return null;
                                final value = v?.trim() ?? '';
                                if (value.isEmpty) return 'Ingresa tu WhatsApp';
                                if (!validarWhatsApp(value)) return 'Formato inválido. Ej: +569XXXXXXXX';
                                return null;
                              },
                            ),

                          const SizedBox(height: 20),

                          // Botón registrarse
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: red,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'Registrarse',
                                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}