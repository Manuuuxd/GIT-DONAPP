// Archivo: eligibility_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../CONFIG/api_config.dart';
// No se importa FormularioResultScreen

class EligibilityStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  final Function(String) onFailure; // <-- NUEVO CALLBACK

  const EligibilityStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onFailure, // <-- NUEVO CALLBACK
  });

  @override
  State<EligibilityStep> createState() => _EligibilityStepState();
}

class _EligibilityStepState extends State<EligibilityStep> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _sleepController = TextEditingController();
  final TextEditingController _lastMealController = TextEditingController();

  bool hasValidId = false;
  String gender = 'Hombre';
  DateTime? _fechaUltimaDonacion;

  final List<String> consultarAntes = [
    "Viajó al extranjero en los últimos 12 meses.",
    "Está consumiendo algún medicamento.",
    "Consumió alcohol o drogas en las últimas 12 horas.",
    "Se realizó un procedimiento dental en los últimos 7 días.",
    "Tiene una enfermedad crónica.",
    "Fue operado/a en los últimos 6 meses."
  ];

  final List<String> noPuedeDonar = [
    "Tiene pareja sexual nueva hace menos de 6 meses.",
    "Tuvo más de una pareja sexual en los últimos 6 meses.",
    "Tuvo relaciones con personas que ejercen comercio sexual.",
    "Tuvo diarrea en los últimos 14 días.",
    "Se ha inyectado drogas ilegales.",
    "Tomó antibióticos en los últimos 7 días.",
    "Está embarazada o tuvo parto/aborto en los últimos 6 meses.",
    "Se hizo tatuajes, piercings o acupuntura en los últimos 6 meses.",
    "Vivió en zonas de malaria más de 6 meses en su vida."
  ];

  final Map<String, bool> _consultarChecks = {};
  final Map<String, bool> _noDonarChecks = {};

  @override
  void initState() {
    super.initState();
    for (var c in consultarAntes) {
      _consultarChecks[c] = false;
    }
    for (var c in noPuedeDonar) {
      _noDonarChecks[c] = false;
    }
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    if (token.isEmpty) return;

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint("api/users/me/")),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fechaStr = data['profile']['fecha_ultima_donacion'];
      if (fechaStr != null) {
        setState(() {
          _fechaUltimaDonacion = DateTime.tryParse(fechaStr);
        });
      }
    }
  }

  void _evaluar() async {
    if (!_formKey.currentState!.validate()) return;

    final int edad = int.tryParse(_ageController.text) ?? 0;
    final int peso = int.tryParse(_weightController.text) ?? 0;
    final int horasSueno = int.tryParse(_sleepController.text) ?? 0;
    final int horasComida = int.tryParse(_lastMealController.text) ?? 0;

    final criteriosExcluyentes =
        _noDonarChecks.entries.where((e) => e.value).map((e) => e.key).toList();
    final criteriosConsulta =
        _consultarChecks.entries.where((e) => e.value).map((e) => e.key).toList();

    final List<String> razones = [];
    DateTime? fechaEstimada;

    if (!hasValidId) razones.add("No tiene documento de identificación válido");
    if (edad < 18 || edad > 65) razones.add("Edad fuera del rango permitido");
    if (peso < 50) razones.add("Peso menor a 50 kg");
    if (horasSueno < 5) razones.add("Menos de 5 horas de sueño");
    if (horasComida > 5) razones.add("Última comida fue hace más de 5 horas");

    int mesesDesdeUltimaDonacion = 999;
    if (_fechaUltimaDonacion != null) {
      mesesDesdeUltimaDonacion =
          (DateTime.now().difference(_fechaUltimaDonacion!).inDays / 30).floor();
    }

    if (gender == 'Hombre' && mesesDesdeUltimaDonacion < 3) {
      razones.add("Debe esperar al menos 3 meses entre donaciones");
      fechaEstimada = _fechaUltimaDonacion?.add(const Duration(days: 90));
    }
    if (gender == 'Mujer' && mesesDesdeUltimaDonacion < 4) {
      razones.add("Debe esperar al menos 4 meses entre donaciones");
      fechaEstimada = _fechaUltimaDonacion?.add(const Duration(days: 120));
    }

    final bool esExcluyente = criteriosExcluyentes.isNotEmpty;
    final bool debeConsultar = criteriosConsulta.isNotEmpty;
    final bool noCumpleBasico = razones.isNotEmpty;

    // --- CAMBIO IMPORTANTE ---
    if (esExcluyente || noCumpleBasico) {
      String mensaje = "Lamentablemente no puedes continuar con la donación.\n\n";

      if (criteriosExcluyentes.isNotEmpty) {
        mensaje += "Criterios excluyentes:\n";
        for (var e in criteriosExcluyentes) {
          mensaje += "- $e\n";
        }
        mensaje +=
            "\nPor razones médicas, no podrás donar sangre. Te recomendamos consultar con un especialista.";
      } else {
        mensaje += "Motivos básicos no cumplidos:\n";
        for (var r in razones) {
          mensaje += "- $r\n";
        }
        if (fechaEstimada != null) {
          mensaje +=
              "\nPodrás volver a donar aproximadamente el ${fechaEstimada.day}/${fechaEstimada.month}/${fechaEstimada.year}.";
        } else {
          mensaje +=
              "\nPor favor espera hasta cumplir los requisitos básicos antes de intentar nuevamente.";
        }
      }

      // En lugar de navegar, llama al callback de fallo
      widget.onFailure(mensaje);
      return;
    }
    // --- FIN DEL CAMBIO ---

    widget.onNext({
      'eligible': true,
      'consultar': debeConsultar,
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- CAMBIO ---
    // Se quitó Scaffold, AppBar y SingleChildScrollView
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // <-- AÑADIDO
        children: [
          const Icon(Icons.assignment, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text("Formulario de Elegibilidad",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text("¿Tiene documento de identificación válido?"),
            value: hasValidId,
            onChanged: (v) => setState(() => hasValidId = v),
          ),
          DropdownButtonFormField<String>(
            value: gender,
            decoration: const InputDecoration(labelText: "Género"),
            items: const [
              DropdownMenuItem(value: 'Hombre', child: Text('Hombre')),
              DropdownMenuItem(value: 'Mujer', child: Text('Mujer')),
            ],
            onChanged: (v) => setState(() => gender = v!),
          ),

          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(labelText: "Edad"),
            keyboardType: TextInputType.number,
            validator: (value) {
              final edad = int.tryParse(value ?? '');
              if (edad == null) return 'Ingrese una edad válida';
              if (edad < 18 || edad > 65) return 'Edad fuera del rango (18–65)';
              return null;
            },
          ),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(labelText: "Peso (kg)"),
            keyboardType: TextInputType.number,
            validator: (value) {
              final peso = int.tryParse(value ?? '');
              if (peso == null) return 'Ingrese un peso válido';
              if (peso < 50) return 'Debe pesar al menos 50 kg';
              return null;
            },
          ),
          TextFormField(
            controller: _sleepController,
            decoration: const InputDecoration(labelText: "Horas de sueño"),
            keyboardType: TextInputType.number,
            validator: (value) {
              final h = int.tryParse(value ?? '');
              if (h == null) return 'Ingrese las horas de sueño';
              if (h < 5) return 'Debe dormir al menos 5 horas';
              return null;
            },
          ),
          TextFormField(
            controller: _lastMealController,
            decoration: const InputDecoration(labelText: "Horas desde la última comida"),
            keyboardType: TextInputType.number,
            validator: (value) {
              final h = int.tryParse(value ?? '');
              if (h == null) return 'Ingrese las horas desde la última comida';
              if (h > 5) return 'Debe haber comido hace menos de 5 horas';
              return null;
            },
          ),
          const SizedBox(height: 16),

          ExpansionTile(
            title: const Text("Consultas antes de donar"),
            children: consultarAntes
                .map((e) => CheckboxListTile(
                      title: Text(e),
                      value: _consultarChecks[e],
                      onChanged: (v) => setState(() => _consultarChecks[e] = v!),
                    ))
                .toList(),
          ),
          ExpansionTile(
            title: const Text("Criterios excluyentes"),
            children: noPuedeDonar
                .map((e) => CheckboxListTile(
                      title: Text(e),
                      value: _noDonarChecks[e],
                      onChanged: (v) => setState(() => _noDonarChecks[e] = v!),
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Atrás"),
              ),
              ElevatedButton.icon(
                onPressed: _evaluar,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Evaluar y continuar"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}