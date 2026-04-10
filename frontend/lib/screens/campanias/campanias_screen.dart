import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'crear_campania_screen.dart';
import 'detalle_campania_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enviar_notificacion_screen.dart'; // Importa la nueva pantalla
import 'package:donapp_android/CONFIG/api_config.dart';


class CampaniasScreen extends StatefulWidget {
  const CampaniasScreen({super.key});

  @override
  State<CampaniasScreen> createState() => _CampaniasScreenState();
}

class _CampaniasScreenState extends State<CampaniasScreen> {
  List<dynamic> _campanias = [];
  String _selectedEstado = "Todos";

  final List<String> _estados = [
    "Todos",
    "activa",
    "cerrada",
    "borrador",
    "cancelada"
  ];

  @override
  void initState() {
    super.initState();
    _fetchCampanias();
  }

  Future<void> _fetchCampanias() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('authToken');

    if (jwtToken == null) {
      throw Exception("No JWT token found");
    }

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint("api/campanias/campanias/")),
      headers: {
        "Authorization": "Bearer $jwtToken",
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _campanias = jsonDecode(response.body);
      });
    } else {
      throw Exception("Error al cargar campañas: ${response.statusCode} - ${response.body}");
    }
  }

  List<dynamic> get _filteredCampanias {
    if (_selectedEstado == "Todos") return _campanias;
    return _campanias.where((c) => c["estado"] == _selectedEstado).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Campañas")),
      body: Column(
        children: [
          // Filtro por estado
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              value: _selectedEstado,
              decoration: const InputDecoration(
                labelText: "Filtrar por estado",
                border: OutlineInputBorder(),
              ),
              items: _estados
                  .map((estado) =>
                      DropdownMenuItem(value: estado, child: Text(estado)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedEstado = value!;
                });
              },
            ),
          ),
          const SizedBox(height: 10),

          // Listado de campañas
          Expanded(
            child: _filteredCampanias.isEmpty
                ? const Center(child: Text("No hay campañas"))
                : ListView.builder(
                    itemCount: _filteredCampanias.length,
                    itemBuilder: (context, index) {
                      final c = _filteredCampanias[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(c["nombre"] ?? "Sin nombre"),
                          subtitle: Text(
                            "${c["direccion"] ?? ""}\n${c["fecha"] ?? ""}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(c["estado"] ?? ""),
                              const SizedBox(width: 10),
                              // Botón editar si la campaña está activa o en borrador
                              if (c["estado"] == "activa" ||
                                  c["estado"] == "borrador")
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final jwtToken =
                                        prefs.getString('authToken');

                                    if (jwtToken != null) {
                                      final editada = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CrearCampaniaScreen(
                                            jwtToken: jwtToken,
                                            campania: c,
                                          ),
                                        ),
                                      );

                                      if (editada == true) {
                                        _fetchCampanias();
                                      }
                                    }
                                  },
                                ),
                              // Nuevo botón para enviar notificación
                              IconButton(
                                icon: const Icon(Icons.send, color: Colors.green),
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final jwtToken = prefs.getString('authToken');
                                  
                                  if (jwtToken != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EnviarNotificacionScreen(
                                          jwtToken: jwtToken,
                                          campania: c,
                                        ),
                                      ),
                                    );
                                  } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                        content: Text("No se encontró token de autenticación")),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetalleCampaniaScreen(campania: c),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      // Botón para crear nueva campaña
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          final jwtToken = prefs.getString('authToken');

          if (jwtToken == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("No se encontró token de autenticación")),
            );
            return;
          }

          final creada = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CrearCampaniaScreen(jwtToken: jwtToken),
            ),
          );

          if (creada == true) {
            _fetchCampanias();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

