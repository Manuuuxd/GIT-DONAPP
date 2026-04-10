// Archivo: FormularioResultScreen.dart (COMPLETO)

import 'package:flutter/material.dart';

// 1. VERSIÓN MÓVIL (PANTALLA COMPLETA)
class ElegibilityResultScreen extends StatelessWidget {
  final String detalle;

  const ElegibilityResultScreen({super.key, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resultado de Elegibilidad"),
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ElegibilityResult(detalle: detalle, isDialog: false),
      ),
    );
  }
}


// 2. VERSIÓN WEB (CONTENIDO DEL DIÁLOGO)
class ElegibilityResult extends StatelessWidget {
  final String detalle;
  final bool isDialog;

  const ElegibilityResult({
    super.key, 
    required this.detalle,
    this.isDialog = true, 
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDialog ? null : const [ 
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.health_and_safety, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "Resultado de Evaluación",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            detalle,
            style: const TextStyle(fontSize: 16, height: 1.4),
          ),

          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () {
              if (isDialog) {
                Navigator.of(context).pop(); 
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            icon: Icon(isDialog ? Icons.close : Icons.home),
            label: Text(isDialog ? "Cerrar" : "Volver al inicio"),
          )
        ],
      ),
    );
  }
}