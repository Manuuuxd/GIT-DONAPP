// Archivo: formulario_donacion.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import 'intro_step.dart';
import 'eligibility_step.dart';
import 'location_step.dart';
import 'datetime_step.dart';
import 'personal_data_step.dart';
import 'confirmation_step.dart';
import 'FormularioResultScreen.dart'; // <-- Necesario para el fallo

class FormularioDonacion extends StatefulWidget {
  const FormularioDonacion({super.key});

  @override
  State<FormularioDonacion> createState() => _FormularioDonacionState();
}

class _FormularioDonacionState extends State<FormularioDonacion> {
  int currentStep = 0;
  final Map<String, dynamic> formData = {};

  void nextStep([Map<String, dynamic>? data]) {
    if (data != null) formData.addAll(data);
    if (currentStep < 5) setState(() => currentStep++);
  }

  void previousStep() {
    if (currentStep > 0) setState(() => currentStep--);
  }

  void _handleEligibilityFailure(String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ElegibilityResultScreen(detalle: message),
      ),
    );
  }

  void _handleConfirmation() {
    // No se necesita acción aquí, ConfirmationStep maneja la navegación final.
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      IntroStep(onNext: nextStep),
      EligibilityStep(
        onNext: nextStep,
        onBack: previousStep,
        onFailure: _handleEligibilityFailure, 
      ),
      
      // --- 🌟 CAMBIO AQUÍ 🌟 ---
      // Le decimos a LocationStep que NO es un invitado (está en la app móvil)
      LocationStep(
        onNext: nextStep, 
        onBack: previousStep,
        isGuest: false, // <-- AÑADIDO
      ), 
      // --- FIN CAMBIO ---
      
      DateTimeStep(onNext: nextStep, onBack: previousStep),
      PersonalDataStep(onNext: nextStep, onBack: previousStep),
      
      // --- 🌟 CAMBIO AQUÍ 🌟 ---
      // Le decimos a ConfirmationStep que NO es un invitado
      ConfirmationStep(
        onBack: previousStep,
        data: formData,
        onConfirm: _handleConfirmation,
        isGuest: false, // <-- AÑADIDO
      ),
      // --- FIN CAMBIO ---
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Agendar Donación – Paso ${currentStep + 1} de 6"),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / 6,
            color: Colors.redAccent,
            backgroundColor: Colors.red.shade100,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: steps[currentStep],
      ),
    );
  }
}