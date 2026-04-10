import 'package:flutter/material.dart';
import 'package:donapp_android/services/appointment_service.dart';
import 'package:intl/intl.dart'; // Para parsear fecha/hora

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AppointmentService service = AppointmentService();
  bool isLoading = true;
  List<Appointment> appointments = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final data = await service.fetchHistory();
      setState(() {
        appointments = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  bool _isFutureAppointment(Appointment a) {
    try {
      final dateTime =
          DateFormat("yyyy-MM-dd HH:mm").parse("${a.date} ${a.time}");
      return dateTime.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Future<void> _cancelAppointment(Appointment a) async {
    if (a.id == null) return; // no se puede cancelar si id es null

    final motivos = [
      "No puedo asistir",
      "Problema de salud",
      "Cambio de horario",
      "Otro"
    ];
    
    // Obtener el tema para los diálogos
    final colorScheme = Theme.of(context).colorScheme;

    String? motivoSeleccionado = await showDialog<String>(
      context: context,
      builder: (context) {
        String? selected;
        return AlertDialog(
          backgroundColor: colorScheme.surface, // <-- Cambio
          title: Text("Cancelar cita", style: TextStyle(color: colorScheme.onSurface)), // <-- Cambio
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: motivos.map((m) {
              return RadioListTile<String>(
                title: Text(m, style: TextStyle(color: colorScheme.onSurface)), // <-- Cambio
                value: m,
                groupValue: selected,
                selectedTileColor: colorScheme.primary.withOpacity(0.1), // <-- Cambio
                activeColor: colorScheme.primary, // <-- Cambio
                onChanged: (value) {
                  // No podemos usar setState fuera de un StatefulBuilder, pero podemos manejar la selección
                  selected = value;
                  Navigator.of(context).pop(value);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cerrar", style: TextStyle(color: colorScheme.primary)), // <-- Cambio
            ),
          ],
        );
      },
    );

    if (motivoSeleccionado != null) {
      try {
        final success =
            await service.cancelAppointment(a.id!, motivoSeleccionado);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cita cancelada correctamente")),
          );
          _loadHistory(); // refrescar historial
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al cancelar la cita")),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Obtenemos el tema ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      appBar: AppBar(
        title: const Text("Historial de Citas"),
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        foregroundColor: colorScheme.onBackground, // <-- Cambio
        elevation: 1, // <-- Agregado para mejor visual
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(child: Text(error, style: TextStyle(color: colorScheme.error))) // <-- Cambio
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final a = appointments[index];
                    final isFuture = _isFutureAppointment(a);

                    return Card(
                      color: colorScheme.surface, // <-- Cambio
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text("Centro: ${a.centerName ?? 'Desconocido'}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${a.date} ${a.time}"),
                            if (a.status != null && a.status != "active")
                              Text(
                                "Estado: ${a.status}${a.cancellationReason != null ? ' (${a.cancellationReason})' : ''}",
                                style: TextStyle(color: colorScheme.error), // <-- Cambio
                              ),
                          ],
                        ),
                        trailing: isFuture &&
                                  a.status != "cancelled" &&
                                  a.id != null
                              ? IconButton(
                                  icon: Icon(Icons.cancel, color: colorScheme.error), // <-- Cambio
                                  onPressed: () => _cancelAppointment(a),
                                )
                              : null,
                      ),
                    );
                  },
                ),
    );
  }
}
