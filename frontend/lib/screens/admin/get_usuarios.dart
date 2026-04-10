// lib/admin/get_usuarios.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';

/// ---------------------------
/// API: listar / filtrar usuarios
/// ---------------------------
Future<List<UserProfile>> fetchUsers({
  String? region,
  String? provincia,
  String? comuna,
  bool? aptoParaDonar,
  String? sexo,
  String? tipoSangre,
  DateTime? fechaDesde,
  DateTime? fechaHasta,
}) async {
  final String baseUrl = ApiConfig.endpoint("api/users/filtrar_usuarios/");
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  if (token == null) return [];

  final queryParams = {
    if (region != null) 'region': region,
    if (provincia != null) 'provincia': provincia,
    if (comuna != null) 'comuna': comuna,
    if (aptoParaDonar != null) 'apto_para_donar': aptoParaDonar.toString(),
    if (sexo != null) 'sexo': sexo,
    if (tipoSangre != null) 'tipo_sangre': tipoSangre,
    if (fechaDesde != null) 'fecha_desde': fechaDesde.toIso8601String().split('T')[0],
    if (fechaHasta != null) 'fecha_hasta': fechaHasta.toIso8601String().split('T')[0],
  };

  final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> usuarios = json.decode(response.body);
    return usuarios.map((item) => UserProfile.fromJson(item)).toList();
  } else {
    throw Exception('Error: ${response.statusCode}');
  }
}

/// ---------------------------
/// UI: pantalla de usuarios
/// ---------------------------
/// Puedes navegar a esta pantalla desde el chat:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const usuarios.UsuariosScreen()));
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({
    super.key,
    this.region,
    this.provincia,
    this.comuna,
    this.aptoParaDonar,
    this.sexo,
    this.tipoSangre,
    this.fechaDesde,
    this.fechaHasta,
  });

  // filtros iniciales opcionales (por si el backend te los manda)
  final String? region;
  final String? provincia;
  final String? comuna;
  final bool? aptoParaDonar;
  final String? sexo;
  final String? tipoSangre;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late Future<List<UserProfile>> _future;

  // estado de filtros (se inicializa con los del widget si vienen)
  String? _region;
  String? _provincia;
  String? _comuna;
  bool? _aptoParaDonar;
  String? _sexo;
  String? _tipoSangre;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  @override
  void initState() {
    super.initState();
    _region = widget.region;
    _provincia = widget.provincia;
    _comuna = widget.comuna;
    _aptoParaDonar = widget.aptoParaDonar;
    _sexo = widget.sexo;
    _tipoSangre = widget.tipoSangre;
    _fechaDesde = widget.fechaDesde;
    _fechaHasta = widget.fechaHasta;

    _future = fetchUsers(
      region: _region,
      provincia: _provincia,
      comuna: _comuna,
      aptoParaDonar: _aptoParaDonar,
      sexo: _sexo,
      tipoSangre: _tipoSangre,
      fechaDesde: _fechaDesde,
      fechaHasta: _fechaHasta,
    );
  }

  void _reload() {
    setState(() {
      _future = fetchUsers(
        region: _region,
        provincia: _provincia,
        comuna: _comuna,
        aptoParaDonar: _aptoParaDonar,
        sexo: _sexo,
        tipoSangre: _tipoSangre,
        fechaDesde: _fechaDesde,
        fechaHasta: _fechaHasta,
      );
    });
  }

  Future<void> _pickFechaDesde() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaDesde ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      _fechaDesde = picked;
      _reload();
    }
  }

  Future<void> _pickFechaHasta() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaHasta ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      _fechaHasta = picked;
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros básicos demo — ajusta a tus listas reales
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Apto para donar
                DropdownButton<bool>(
                  value: _aptoParaDonar,
                  hint: const Text('Apto para donar'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Sí')),
                    DropdownMenuItem(value: false, child: Text('No')),
                  ],
                  onChanged: (v) {
                    _aptoParaDonar = v;
                    _reload();
                  },
                ),
                // Sexo
                DropdownButton<String>(
                  value: _sexo,
                  hint: const Text('Sexo'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('M')),
                    DropdownMenuItem(value: 'F', child: Text('F')),
                  ],
                  onChanged: (v) {
                    _sexo = v;
                    _reload();
                  },
                ),
                // Tipo de sangre
                DropdownButton<String>(
                  value: _tipoSangre,
                  hint: const Text('Tipo sangre'),
                  items: const [
                    DropdownMenuItem(value: 'A+', child: Text('A+')),
                    DropdownMenuItem(value: 'O+', child: Text('O+')),
                    DropdownMenuItem(value: 'B+', child: Text('B+')),
                    DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                    DropdownMenuItem(value: 'A-', child: Text('A-')),
                    DropdownMenuItem(value: 'O-', child: Text('O-')),
                    DropdownMenuItem(value: 'B-', child: Text('B-')),
                    DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                  ],
                  onChanged: (v) {
                    _tipoSangre = v;
                    _reload();
                  },
                ),
                // Fechas
                OutlinedButton.icon(
                  onPressed: _pickFechaDesde,
                  icon: const Icon(Icons.date_range),
                  label: Text(_fechaDesde == null ? 'Desde' : _fmtDate(_fechaDesde!)),
                ),
                OutlinedButton.icon(
                  onPressed: _pickFechaHasta,
                  icon: const Icon(Icons.event),
                  label: Text(_fechaHasta == null ? 'Hasta' : _fmtDate(_fechaHasta!)),
                ),
              ],
            ),
          ),

          // Lista
          Expanded(
            child: FutureBuilder<List<UserProfile>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error ${snap.error}'));
                }
                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Sin resultados'));
                }
                return ListView.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final u = data[i];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(u.nombre ?? 'Usuario'),
                      trailing: Text(u.sexo ?? ''),
                      onTap: () {
                        // abre detalle si quieres
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }
}
