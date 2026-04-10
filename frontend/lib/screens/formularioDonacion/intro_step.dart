// Archivo: intro_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';

class IntroStep extends StatelessWidget {
  final VoidCallback onNext;

  const IntroStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      // mainAxisAlignment: MainAxisAlignment.center, // <-- ELIMINADO
      mainAxisSize: MainAxisSize.min, // <-- AÑADIDO
      children: [
        const Icon(Icons.favorite, color: Colors.red, size: 80),
        const SizedBox(height: 20),
        const Text(
          "Bienvenido al proceso de donación",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Te guiaremos paso a paso para verificar tu elegibilidad y agendar tu donación de sangre.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 30),
        ElevatedButton.icon(
          onPressed: onNext,
          icon: const Icon(Icons.arrow_forward),
          label: const Text("Comenzar"),
        ),
      ],
    );
  }
}