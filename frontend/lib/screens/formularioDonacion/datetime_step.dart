// Archivo: datetime_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';

class DateTimeStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const DateTimeStep({super.key, required this.onNext, required this.onBack});

  @override
  State<DateTimeStep> createState() => _DateTimeStepState();
}

class _DateTimeStepState extends State<DateTimeStep> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: now,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => selectedTime = picked);
  }

  void submit() {
    if (selectedDate == null || selectedTime == null) return;
    widget.onNext({
      'date': selectedDate!.toIso8601String(),
      'time': selectedTime!.format(context),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min, // <-- AÑADIDO
      children: [
        const Icon(Icons.access_time, color: Colors.red, size: 60),
        const SizedBox(height: 20),
        const Text("Selecciona fecha y hora",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ListTile(
          title: Text(selectedDate == null
              ? "Elegir fecha"
              : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}"),
          trailing: const Icon(Icons.calendar_today),
          onTap: pickDate,
        ),
        ListTile(
          title: Text(
              selectedTime == null ? "Elegir hora" : selectedTime!.format(context)),
          trailing: const Icon(Icons.access_time),
          onTap: pickTime,
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
              onPressed:
                  (selectedDate != null && selectedTime != null) ? submit : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Siguiente"),
            ),
          ],
        ),
      ],
    );
  }
}