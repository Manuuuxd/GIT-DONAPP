// Archivo: personal_data_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';

class PersonalDataStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const PersonalDataStep({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<PersonalDataStep> createState() => _PersonalDataStepState();
}

class _PersonalDataStepState extends State<PersonalDataStep> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _rut = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();

  void submit() {
    if (_formKey.currentState!.validate()) {
      widget.onNext({
        'name': _name.text.trim(),
        'rut': _rut.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // <-- AÑADIDO
        children: [
          const Icon(Icons.person, color: Colors.red, size: 60),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(labelText: "Nombre completo"),
            validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
          ),
          TextFormField(
            controller: _rut,
            decoration: const InputDecoration(labelText: "RUT (sin puntos, con guión)"),
            validator: (v) => v == null || v.isEmpty ? "Campo obligatorio" : null,
          ),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: "Correo electrónico"),
            validator: (v) => v == null || !v.contains('@') ? "Correo inválido" : null,
          ),
          TextFormField(
            controller: _phone,
            decoration: const InputDecoration(labelText: "Teléfono"),
            validator: (v) =>
                v == null || v.length < 8 ? "Teléfono inválido" : null,
          ),
          
          // --- CAMBIO ---
          // const Spacer(), // <-- ELIMINADO
          const SizedBox(height: 40), // <-- Reemplazado por un espacio fijo
          // --- FIN CAMBIO ---

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Atrás"),
              ),
              ElevatedButton.icon(
                onPressed: submit,
                icon: const Icon(Icons.arrow_forward),
                label: const Text("Siguiente"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}