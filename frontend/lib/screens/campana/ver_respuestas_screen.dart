import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerRespuestasScreen extends StatefulWidget {
  final Map<String, dynamic> encuesta;
  VerRespuestasScreen({required this.encuesta});

  @override
  _VerRespuestasScreenState createState() => _VerRespuestasScreenState();
}

class _VerRespuestasScreenState extends State<VerRespuestasScreen> {
  List<dynamic> respuestas = [];
  bool cargando = true;

  Future<void> _cargarRespuestas() async {
    // Nota: El URL es local (10.0.2.2) y fijo. Asumo que es correcto para pruebas.
    final url =
        "http://10.0.2.2:8000/api/responses/?survey=${widget.encuesta["id"]}";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        respuestas = jsonDecode(response.body);
        cargando = false;
      });
    } else {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al cargar respuestas")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarRespuestas();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
      appBar: AppBar(
        title: Text("Respuestas"),
        backgroundColor: theme.scaffoldBackgroundColor, // ✅ Fondo
        foregroundColor: colorScheme.onBackground, // ✅ Color de íconos/texto
        elevation: 0,
      ),
      body: cargando
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary)) // ✅ Adaptar color
          : respuestas.isEmpty
              ? Center(child: Text("No hay respuestas aún")) // ✅ Color se hereda
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: respuestas.length,
                  itemBuilder: (ctx, i) {
                    final respuesta = respuestas[i];
                    final answers = respuesta["answers"] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      color: colorScheme.surface, // ✅ Adaptar color
                      child: ExpansionTile(
                        title: Text(
                          "Respuesta #${respuesta["id"]}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary), // ✅ Adaptar color
                        ),
                        subtitle: Text(
                          respuesta["user"] != null
                              ? "Usuario: ${respuesta["user"]}"
                              : "Anónimo",
                          style: TextStyle(color: colorScheme.onSurfaceVariant), // ✅ Adaptar color
                        ),
                        children: answers.entries.map((e) {
                          return ListTile(
                            leading: Icon(Icons.question_answer,
                                color: colorScheme.secondary), // ✅ Adaptar color
                            title: Text(e.key,
                                style: TextStyle(color: colorScheme.onSurface)), // ✅ Adaptar color
                            subtitle: Text(e.value.toString(),
                                style: TextStyle(color: colorScheme.onSurfaceVariant)), // ✅ Adaptar color
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}