import 'package:flutter/material.dart';
import 'api_service.dart';
import 'configurar_encuesta_screen.dart';

class SeleccionarEncuestaScreen extends StatefulWidget {
  @override
  _SeleccionarEncuestaScreenState createState() =>
      _SeleccionarEncuestaScreenState();
}

class _SeleccionarEncuestaScreenState
    extends State<SeleccionarEncuestaScreen> {
  List<dynamic> encuestas = [];
  Map<String, dynamic>? encuestaSeleccionada;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarEncuestas();
  }

  void cargarEncuestas() async {
    try {
      final data = await ApiService.getSurveys();
      setState(() {
        encuestas = data;
        cargando = false;
      });
    } catch (e) {
      setState(() => cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al cargar encuestas")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: Text("Seleccionar Encuesta")),
      body: cargando
          ? Center(
            // ✅ Usar color primario del tema para el indicador de carga
            child: CircularProgressIndicator(color: theme.colorScheme.primary)
          )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown estilizado Donapp
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                // ✅ Usar color de superficie del tema
                color: theme.colorScheme.surface,
                // ✅ Usar color primario del tema para el borde
                border: Border.all(color: theme.colorScheme.primary, width: 1.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<Map<String, dynamic>>(
                isExpanded: true,
                underline: SizedBox(),
                hint: Text(
                  "Elige una encuesta",
                  // ✅ Usar color onSurface
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: encuestaSeleccionada,
                items: encuestas.map<DropdownMenuItem<Map<String, dynamic>>>((encuesta) {
                  final encuestaMap = encuesta as Map<String, dynamic>; // cast here
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: encuestaMap,
                    child: Text(
                      encuestaMap["title"],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        // ✅ Usar color onSurface
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    encuestaSeleccionada = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),

            if (encuestaSeleccionada != null) ...[
              // Mostrar descripción
              Text(
                encuestaSeleccionada!["description"] ?? "",
                // ✅ Usar color onSurfaceVariant
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              SizedBox(height: 20),

              // Botón para ir a configuración
              ElevatedButton.icon(
                icon: Icon(Icons.settings),
                label: Text("Configurar Encuesta"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConfigurarEncuestaScreen(
                          encuesta: encuestaSeleccionada!),
                    ),
                  );
                },
              )
            ] else
              Expanded(
                child: Center(
                  child: Text(
                    "Selecciona una encuesta para continuar",
                    // ✅ Usar color onSurfaceVariant
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}