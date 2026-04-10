// Archivo: confirmation_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import '../schedule/schedule_confirmation_screen.dart';

class ConfirmationStep extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onBack;
  final VoidCallback onConfirm;
  // --- 🌟 CAMBIO AQUÍ 🌟 ---
  final bool isGuest; // <-- Acepta el flag
  // --- FIN CAMBIO ---

  const ConfirmationStep({
    super.key, 
    required this.data, 
    required this.onBack,
    required this.onConfirm,
    this.isGuest = false, // <-- Añade un default
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 70),
        const SizedBox(height: 20),
        const Text(
          "Confirma tu información",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ListTile(
              title: const Text("Centro"),
              subtitle: Text(data['center'] ?? ""),
            ),
            ListTile(
              title: const Text("Fecha"),
              subtitle: Text(data['date'] ?? ""),
            ),
            ListTile(
              title: const Text("Hora"),
              subtitle: Text(data['time'] ?? ""),
            ),
            ListTile(
              title: const Text("Nombre"),
              subtitle: Text(data['name'] ?? ""),
            ),
            ListTile(
              title: const Text("Correo"),
              subtitle: Text(data['email'] ?? ""),
            ),
            ListTile(
              title: const Text("Teléfono"),
              subtitle: Text(data['phone'] ?? ""),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text("Atrás"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                onConfirm(); 
                final fullData = Map<String, dynamic>.from(data);
                if (data['centerId'] != null) {
                  fullData['centerId'] = data['centerId'];
                }
                
                // --- 🌟 CAMBIO AQUÍ 🌟 ---
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleConfirmationScreen(
                      data: fullData,
                      isGuest: isGuest, // <-- Pasa el flag a la pantalla final
                    ),
                  ),
                );
                // --- FIN CAMBIO ---
              },
              icon: const Icon(Icons.done),
              label: const Text("Confirmar y Agendar"),
            ),
          ],
        ),
      ],
    );
  }
}