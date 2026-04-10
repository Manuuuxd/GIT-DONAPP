import 'package:flutter/material.dart';

class DetalleCampaniaScreen extends StatelessWidget {
  final Map<String, dynamic> campania;

  const DetalleCampaniaScreen({super.key, required this.campania});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(campania["nombre"] ?? "Detalle")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dirección: ${campania["direccion"] ?? ""}"),
            Text("Comuna: ${campania["comuna"] ?? ""}"),
            Text("Fecha: ${campania["fecha"] ?? ""}"),
            Text("Horario: ${campania["horario"] ?? ""}"),
            Text("Grupo sanguíneo: ${campania["grupo_sanguineo"] ?? ""}"),
            Text("Rh: ${campania["rh"] ?? ""}"),
            Text("Estado: ${campania["estado"] ?? ""}"),
          ],
        ),
      ),
    );
  }
}
