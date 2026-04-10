import 'package:flutter/material.dart';
import 'package:donapp_android/services/appointment_service.dart';
import 'package:donapp_android/colours/app_colors.dart'; // Mantenemos para los colores semánticos si se usan

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final AppointmentService service = AppointmentService();

  final _formKey = GlobalKey<FormState>();

  List<DonationCenter> centers = [];
  DonationCenter? selectedCenter;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final TextEditingController rutController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool isSubmitting = false;
  bool isLoadingCenters = true;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  @override
  void dispose() {
    rutController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    try {
      final fetchedCenters = await service.fetchCenters();
      if (!mounted) return;
      setState(() {
        centers = fetchedCenters;
        isLoadingCenters = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingCenters = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar centros: $e")),
      );
    }
  }

  bool get isFormValid =>
      rutController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      selectedCenter != null &&
      selectedDate != null &&
      selectedTime != null;

  Future<void> _onSchedulePressed() async {
    if (!_formKey.currentState!.validate()) return;
    if (!isFormValid) return;

    setState(() => isSubmitting = true);

    final appt = Appointment(
      id: null,
      rut: rutController.text.trim(),
      email: emailController.text.trim(),
      date: selectedDate!.toIso8601String().split("T")[0],
      time:
          "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
      centerId: selectedCenter!.id,
    );

    final success = await service.scheduleAppointment(appt);
    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu cita ha sido agendada con éxito.")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al agendar cita. Intenta contactar por teléfono."),
        ),
      );
    }
  }

  // --- Adaptamos la decoración de input para usar el tema ---
  InputDecoration _dec(BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: colorScheme.primary), // <-- Cambio
      filled: true,
      fillColor: colorScheme.surface, // <-- Cambio
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline), // <-- Cambio
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline), // <-- Cambio
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5), // <-- Cambio
      ),
      // El color de texto (label/hint) se hereda de los colores del tema
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant), 
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Obtenemos el tema ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // final blue50 = AppColors.customBlue[50]!; // Ya no es necesario
    // final blue100 = AppColors.customBlue[100]!; // Ya no es necesario
    // final blue700 = AppColors.customBlue[700]!; // Ya no es necesario

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        elevation: 0,
        title: Text(
          "Agendar Cita",
          style: TextStyle(
            color: colorScheme.onBackground, // <-- Cambio
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground), // <-- Cambio
      ),
      body: SafeArea(
        child: isLoadingCenters
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header compacto
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer, // <-- Cambio
                          borderRadius: BorderRadius.circular(12),
                          border: Border.fromBorderSide(
                            BorderSide(color: colorScheme.outline), // <-- Cambio
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1), // <-- Cambio
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.event_available_rounded,
                                  color: colorScheme.primary, size: 22), // <-- Cambio
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Completa los datos para agendar tu donación",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onPrimaryContainer, // <-- Cambio
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // RUT
                      TextFormField(
                        controller: rutController,
                        textInputAction: TextInputAction.next,
                        decoration: _dec( // <-- Pasamos context
                          context,
                          label: "RUT",
                          hint: "12.345.678-9",
                          icon: Icons.badge_outlined,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Ingresa tu RUT" : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: _dec( // <-- Pasamos context
                          context,
                          label: "Correo electrónico",
                          hint: "tucorreo@ejemplo.com",
                          icon: Icons.mail_outline,
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? "Ingresa tu correo" : null,
                      ),
                      const SizedBox(height: 12),

                      // Centro
                      DropdownButtonFormField<DonationCenter>(
                        value: selectedCenter,
                        isExpanded: true,
                        isDense: true,
                        decoration: _dec( // <-- Pasamos context
                          context,
                          label: "Centro de donación",
                          icon: Icons.location_on_outlined,
                        ),
                        dropdownColor: colorScheme.surface, // <-- Cambio: Fondo del menú
                        items: centers
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    "${c.name} – ${c.comuna}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (c) => setState(() => selectedCenter = c),
                        validator: (v) =>
                            v == null ? "Selecciona un centro" : null,
                      ),
                      const SizedBox(height: 12),

                      // Fecha & Hora (sin controladores temporales)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              initialValue: selectedDate == null
                                  ? ""
                                  : selectedDate!
                                      .toIso8601String()
                                      .split("T")[0],
                              decoration: _dec( // <-- Pasamos context
                                context,
                                label: "Fecha",
                                hint: "Selecciona fecha",
                                icon: Icons.calendar_today_outlined,
                              ),
                              onTap: () async {
                                final now = DateTime.now();
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? now,
                                  firstDate: now,
                                  lastDate: now.add(const Duration(days: 365)),
                                  // Los selectores de fecha/hora son adaptativos, pero podemos forzar el color del botón.
                                  builder: (context, child) {
                                    return Theme(
                                      data: theme.copyWith(
                                        colorScheme: colorScheme.copyWith(
                                          primary: colorScheme.primary, 
                                          onPrimary: colorScheme.onPrimary,
                                          surface: colorScheme.surface,
                                          onSurface: colorScheme.onSurface,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  }
                                );
                                if (date != null) {
                                  setState(() => selectedDate = date);
                                }
                              },
                              validator: (_) =>
                                  selectedDate == null ? "Selecciona una fecha" : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              readOnly: true,
                              initialValue: selectedTime == null
                                  ? ""
                                  : selectedTime!.format(context),
                              decoration: _dec( // <-- Pasamos context
                                context,
                                label: "Hora",
                                hint: "Selecciona hora",
                                icon: Icons.schedule,
                              ),
                              onTap: () async {
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime ?? TimeOfDay.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: theme.copyWith(
                                        colorScheme: colorScheme.copyWith(
                                          primary: colorScheme.primary, 
                                          onPrimary: colorScheme.onPrimary,
                                          surface: colorScheme.surface,
                                          onSurface: colorScheme.onSurface,
                                        ),
                                        textButtonTheme: TextButtonThemeData(
                                          style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  }
                                );
                                if (time != null) {
                                  setState(() => selectedTime = time);
                                }
                              },
                              validator: (_) =>
                                  selectedTime == null ? "Selecciona una hora" : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Botón principal
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: (isFormValid && !isSubmitting)
                              ? _onSchedulePressed
                              : null,
                          icon: isSubmitting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary, // <-- Cambio
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            isSubmitting ? "Agendando..." : "Agendar",
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary, // <-- Cambio
                            foregroundColor: colorScheme.onPrimary, // <-- Cambio
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Borrar / Reset
                      TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () {
                                setState(() {
                                  rutController.clear();
                                  emailController.clear();
                                  selectedCenter = null;
                                  selectedDate = null;
                                  selectedTime = null;
                                });
                              },
                        icon: Icon(Icons.refresh, color: colorScheme.onSurfaceVariant), // <-- Cambio
                        label: Text("Limpiar campos", style: TextStyle(color: colorScheme.onSurfaceVariant)), // <-- Cambio
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
