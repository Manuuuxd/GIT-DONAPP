import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../schedule/schedule_screen.dart';


class EnviarNotificacionScreen extends StatefulWidget {
  final String jwtToken;
  final Map<String, dynamic> campania;

  const EnviarNotificacionScreen({
    super.key,
    required this.jwtToken,
    required this.campania,
  });

  @override
  State<EnviarNotificacionScreen> createState() =>
      _EnviarNotificacionScreenState();
}

class _EnviarNotificacionScreenState extends State<EnviarNotificacionScreen> {
  List<dynamic> destinatarios = [];
  bool cargando = true;
  bool _enviando = false;

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController(); // Programación

@override
void initState() {
  super.initState();
  _cargarDestinatarios();
  _tituloController.text = widget.campania['nombre'] ?? '';

  // 🔥 Listener de notificaciones
OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) async {
  // ✅ Esta es la forma correcta de acceder al actionId en las versiones más recientes
  final actionId = event.result.actionId; 
  final envioId = event.notification.additionalData?["envio_id"];

  if (envioId == null) return;

  String? reaccion;
if (actionId == "agendar") {
  reaccion = "agendar";
  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleScreen(), // tu screen aquí
      ),
    );
  }
} else if (actionId == "descartar") {
    reaccion = "opt_out";
  }

  if (reaccion != null) {
    final response = await http.post(
      Uri.parse("http://10.0.2.2:8000/api/envios/$envioId/reaccionar/"),
      headers: {
        "Authorization": "Bearer ${widget.jwtToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"reaccion": reaccion}),
    );
    print("Reacción enviada: ${response.body}");
  }
});

}

  @override
  void dispose() {
    _tituloController.dispose();
    _mensajeController.dispose();
    _busquedaController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  Future<void> _cargarDestinatarios() async {
    final url =
        "http://10.0.2.2:8000/api/campanias/campanias/${widget.campania['id']}/destinatarios/";
    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer ${widget.jwtToken}",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        destinatarios = data['destinatarios']
            .where((u) => u['reaccion'] != 'opt_out') // filtra opt_out
            .toList();
        cargando = false;
});



    } else {
      setState(() => cargando = false);
      print("Error ${response.statusCode}: ${response.body}");
    }
  }

  Future<void> _enviarNotificaciones() async {
    if (_tituloController.text.isEmpty || _mensajeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El título y el mensaje no pueden estar vacíos.")),
      );
      return;
    }

    setState(() => _enviando = true);

    final body = {
      "titulo": _tituloController.text,
      "mensaje": _mensajeController.text,
    };
    if (_fechaController.text.isNotEmpty) {
      body["programado_para"] = _fechaController.text;
    }

    final url =
        "http://10.0.2.2:8000/api/campanias/campanias/${widget.campania['id']}/enviar/";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer ${widget.jwtToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    setState(() => _enviando = false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final totalEnvios = data['total_envios'] ?? 0;
      final errores = (data['errores'] as List<dynamic>?) ?? [];

      String mensajeSnack = "Enviadas $totalEnvios notificaciones.";
      if (errores.isNotEmpty) {
        mensajeSnack += " Errores en: ${errores.join(", ")}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensajeSnack)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al enviar notificaciones: ${response.body}"),
        ),
      );
    }
  }

  Future<void> _previsualizar() async {
    final url =
        "http://10.0.2.2:8000/api/campanias/campanias/${widget.campania['id']}/previsualizar/";
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer ${widget.jwtToken}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "titulo": _tituloController.text,
        "mensaje": _mensajeController.text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Previsualización"),
          content: Text(
              "Push:\n${data['preview_push']}\n\nEmail:\n${data['preview_email']}"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"))
          ],
        ),
      );
    }
  }

  IconData _getIconForPref(String pref) {
    switch (pref) {
      case 'push':
        return Icons.notifications_active;
      case 'whatsapp':
        return FontAwesomeIcons.whatsapp;
      case 'correo':
        return Icons.email;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getColorForPref(String pref) {
    switch (pref) {
      case 'push':
        return Colors.blue.shade200;
      case 'whatsapp':
        return Colors.green.shade200;
      case 'correo':
        return Colors.orange.shade200;
      default:
        return Colors.grey;
    }
  }

  List<dynamic> _filtrarDestinatarios(String query) {
    if (query.isEmpty) return destinatarios;
    return destinatarios.where((u) {
      final nombre = u['nombre'].toString().toLowerCase();
      final email = u['email'].toString().toLowerCase();
      return nombre.contains(query.toLowerCase()) ||
          email.contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = _filtrarDestinatarios(_busquedaController.text);

    return Scaffold(
      appBar: AppBar(
        title: Text("Enviar Notificaciones - ${widget.campania['nombre']}"),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: "Título de la notificación",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      labelText: "Mensaje a enviar",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _fechaController,
                    decoration: const InputDecoration(
                      labelText: "Fecha/Hora envío (YYYY-MM-DD HH:MM)",
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _enviando ? null : _previsualizar,
                        child: const Text("Previsualizar"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _enviando ? null : _enviarNotificaciones,
                        child: _enviando
                            ? const CircularProgressIndicator()
                            : const Text("Enviar"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _busquedaController,
                    decoration: const InputDecoration(
                      labelText: "Buscar usuario por nombre o email",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (_, index) {
                        final u = filtrados[index];
                        final preferencias =
                            (u['preferencias_notificacion'] as List<dynamic>?)
                                    ?.cast<String>() ??
                                [];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            title: Text(
                              "${u['nombre']} ${u['apellido'] ?? ''}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text("Tipo de sangre: ${u['tipo_sangre'] ?? 'N/A'}"),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 6,
                                  children: preferencias.map((pref) {
                                    return Chip(
                                      avatar: Icon(
                                        _getIconForPref(pref),
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      label: Text(pref),
                                      backgroundColor: _getColorForPref(pref),
                                      labelStyle:
                                          const TextStyle(color: Colors.white),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}










