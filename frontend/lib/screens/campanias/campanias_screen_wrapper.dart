import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class CampaniasScreenWrapper extends StatefulWidget {
  const CampaniasScreenWrapper({super.key});

  @override
  State<CampaniasScreenWrapper> createState() => _CampaniasScreenWrapperState();
}

class _CampaniasScreenWrapperState extends State<CampaniasScreenWrapper> {
  List<dynamic> _campanias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _fetchCampanias();
  }

  Future<void> _fetchCampanias() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Cambia la URL por la de tu backend Django
      final response = await http.get(Uri.parse("http://10.0.2.2/api/campanias/"));
      if (response.statusCode == 200) {
        setState(() {
          _campanias = jsonDecode(response.body);
        });
      } else {
        throw Exception("Error al cargar campañas: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error de conexión: $e");
    }

    setState(() {
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _cargando
        ? const Center(child: CircularProgressIndicator())
        : _campanias.isEmpty
            ? const Center(child: Text("No hay campañas disponibles"))
            : ListView.builder(
                itemCount: _campanias.length,
                itemBuilder: (context, index) {
                  final c = _campanias[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(c["nombre"] ?? "Sin nombre"),
                      subtitle: Text("${c["direccion"] ?? ""}\n${c["fecha"] ?? ""}"),
                      trailing: Text(c["estado"] ?? ""),
                    ),
                  );
                },
              );
  }
}
