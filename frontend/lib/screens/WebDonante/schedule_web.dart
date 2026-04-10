import 'package:flutter/material.dart';
import 'package:donapp_android/services/appointment_service.dart';
import 'package:donapp_android/colours/app_colors.dart';

class ScheduleScreenweb extends StatefulWidget {
  final Future<Map<String, String>> fetchDonorData;

  const ScheduleScreenweb({
    super.key,
    required this.fetchDonorData,
  });

  @override
  State<ScheduleScreenweb> createState() => _ScheduleScreenwebState();
}

class _ScheduleScreenwebState extends State<ScheduleScreenweb> {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? "Tu cita ha sido agendada con éxito."
            : "Error al agendar cita. Intenta contactar por teléfono."),
      ),
    );

    if (success) {
      rutController.clear();
      emailController.clear();
      setState(() {
        selectedCenter = null;
        selectedDate = null;
        selectedTime = null;
      });
    }
  }

  InputDecoration _dec({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final red700 = AppColors.customRed[700]!;
    final red400 = AppColors.customRed[400]!;
    return InputDecoration(
      isDense: true,
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, color: red700),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOutline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderOutline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: red400, width: 1.5),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: widget.fetchDonorData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error al cargar datos del donante"));
        }

        final donor = snapshot.data ?? {
          'nombre': 'Donante invitado',
          'email': '',
          'rut': '',
        };

        // Inicializa los controladores solo una vez
        rutController.text = donor['rut'] ?? '';
        emailController.text = donor['email'] ?? '';

        final isLogged = donor['email']?.isNotEmpty ?? false;

        return _buildScheduleForm(context, isLogged);
      },
    );
  }

  @override
  Widget _buildScheduleForm(BuildContext context, bool isLogged) {
    final blue100 = AppColors.customRed[100]!;
    final red700 = AppColors.customRed[700]!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: isLoadingCenters
            ? const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        )
            : Card(
          color: AppColors.background,
          elevation: 2,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: blue100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.event_available_rounded,
                            color: red700, size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Agendar donación",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Form fields (grid-friendly on web)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isTwoCols = constraints.maxWidth > 600;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width:
                            isTwoCols ? constraints.maxWidth / 2 - 20 : double.infinity,
                            child:
                            TextFormField(
                              controller: rutController,
                              decoration: _dec(
                                label: "RUT",
                                hint: "12.345.678-9",
                                icon: Icons.badge_outlined,
                              ),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? "Ingresa tu RUT"
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width:
                            isTwoCols ? constraints.maxWidth / 2 - 20 : double.infinity,
                            child: TextFormField(
                              controller: emailController,
                              readOnly: isLogged,
                              decoration: _dec(
                                label: "Correo electrónico",
                                hint: "tucorreo@ejemplo.com",
                                icon: Icons.mail_outline,
                              ),
                              validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? "Ingresa tu correo"
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width:
                            isTwoCols ? constraints.maxWidth / 2 - 20 : double.infinity,
                            child: DropdownButtonFormField<DonationCenter>(
                              value: selectedCenter,
                              isExpanded: true,
                              decoration: _dec(
                                label: "Centro de donación",
                                icon: Icons.location_on_outlined,
                              ),
                              items: centers
                                  .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  "${c.name} – ${c.comuna}",
                                  overflow:
                                  TextOverflow.ellipsis,
                                ),
                              ))
                                  .toList(),
                              onChanged: (c) =>
                                  setState(() => selectedCenter = c),
                              validator: (v) =>
                              v == null ? "Selecciona un centro" : null,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: selectedDate == null
                                        ? ""
                                        : selectedDate!
                                        .toIso8601String()
                                        .split("T")[0],
                                  ),
                                  decoration: _dec(
                                    label: "Fecha",
                                    hint: "Selecciona fecha",
                                    icon: Icons.calendar_today_outlined,
                                  ),
                                  onTap: () async {
                                    final now = DateTime.now();
                                    final date = await showDatePicker(
                                      context: context,
                                      initialDate:
                                      selectedDate ?? now,
                                      firstDate: now,
                                      lastDate: now.add(
                                          const Duration(days: 365)),
                                    );
                                    if (date != null) {
                                      setState(() => selectedDate = date);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                    text: selectedTime == null
                                        ? ""
                                        : selectedTime!.format(context),
                                  ),
                                  decoration: _dec(
                                    label: "Hora",
                                    hint: "Selecciona hora",
                                    icon: Icons.schedule,
                                  ),
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime:
                                      selectedTime ?? TimeOfDay.now(),
                                    );
                                    if (time != null) {
                                      setState(() =>
                                      selectedTime = time);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Botón principal
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                      (isFormValid && !isSubmitting) ? _onSchedulePressed : null,
                      icon: isSubmitting
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        isSubmitting ? "Agendando..." : "Agendar cita",
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: red700,
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
          ),
        ),
      ),
    );
  }
}
