// Archivo: schedule_confirmation_screen.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import 'package:donapp_android/services/appointment_service.dart';
import 'package:donapp_android/colours/app_colors.dart';

class ScheduleConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isGuest;

  const ScheduleConfirmationScreen({
    super.key, 
    required this.data,
    this.isGuest = false,
  });

  @override
  State<ScheduleConfirmationScreen> createState() =>
      _ScheduleConfirmationScreenState();
}

class _ScheduleConfirmationScreenState
    extends State<ScheduleConfirmationScreen> {
  final AppointmentService service = AppointmentService();
  bool isSubmitting = false;
  bool _isConfirmed = false;

  Future<void> _confirmAppointment() async {
    setState(() => isSubmitting = true);

    try {
      final appt = Appointment(
        id: null,
        rut: widget.data['rut'] ?? '',
        email: widget.data['email'] ?? '',
        date: widget.data['date'] ?? '',
        time: widget.data['time'] ?? '',
        centerId: widget.data['centerId'],
      );

      // --- 🌟 CAMBIO AQUÍ: Pasar el flag de invitado 🌟 ---
      final success = await service.scheduleAppointment(appt, isGuest: widget.isGuest);
      // --- FIN CAMBIO ---

      if (!mounted) return;

      if (success) {
        setState(() {
          isSubmitting = false;
          _isConfirmed = true; 
        });
      } else {
        setState(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Error al agendar cita. Intenta nuevamente.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue700 = AppColors.customBlue[700]!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isConfirmed ? "¡Cita Agendada!" : "Confirmar cita",
          style:
              const TextStyle(color: AppColors.onBackground, fontWeight: FontWeight.w800),
        ),
        automaticallyImplyLeading: !_isConfirmed,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.onBackground),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isConfirmed
              ? _buildSuccessBody(context)
              : _buildConfirmationBody(context, blue700),
        ),
      ),
    );
  }

  /// Vista A: Muestra los detalles de la cita para confirmar
  Widget _buildConfirmationBody(BuildContext context, Color blue700) {
    return Card(
      key: const ValueKey('confirmation'),
      color: AppColors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Revisa tus datos antes de confirmar:",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 16),
            _infoTile("Centro", widget.data['center'] ?? ''),
            _infoTile("Fecha", widget.data['date'] ?? ''),
            _infoTile("Hora", widget.data['time'] ?? ''),
            _infoTile("Nombre", widget.data['name'] ?? ''),
            _infoTile("Correo", widget.data['email'] ?? ''),
            _infoTile("Teléfono", widget.data['phone'] ?? ''),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : _confirmAppointment,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  isSubmitting ? "Agendando..." : "Confirmar cita",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista B: Muestra el éxito y la oferta de crear cuenta (CA04)
  Widget _buildSuccessBody(BuildContext context) {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            "¡Tu cita está confirmada!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.onBackground),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            "Recibirás un correo en ${widget.data['email']} con los detalles.",
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.onBackground, fontSize: 16),
          ),
          const SizedBox(height: 40),

          // --- LÓGICA DEL CA04 ---
          if (widget.isGuest) ...[
            const Text(
              "Para ver tu historial, ganar puntos y acceder a todos los beneficios, ¡crea tu cuenta!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.onBackground),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega a la pantalla de Registro y pasa los datos
                Navigator.pushNamed(context, '/register', arguments: widget.data);
              },
              child: const Text("Crear mi cuenta ahora"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                // Vuelve a la página principal de invitado (cierra todo)
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Omitir por ahora"),
            )
          ] else ...[
            // Si NO es invitado (ya está logueado), solo vuelve al inicio
            ElevatedButton(
              onPressed: () {
                // Vuelve al dashboard
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: const Text("Volver al inicio"),
            ),
          ]
          // --- ---------------- ---
        ],
      ),
    );
  }


  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : "-",
              style: const TextStyle(color: AppColors.onBackground),
            ),
          ),
        ],
      ),
    );
  }
}