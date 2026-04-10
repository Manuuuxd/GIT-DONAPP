// Archivo: location_step.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/material.dart';
import 'package:donapp_android/services/appointment_service.dart';
import 'package:donapp_android/colours/app_colors.dart';

class LocationStep extends StatefulWidget {
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;
  // --- 🌟 1. Aceptar el flag 🌟 ---
  final bool isGuest;

  const LocationStep({
    super.key, 
    required this.onNext, 
    required this.onBack,
    this.isGuest = false, // <-- Añadir default
  });

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final AppointmentService service = AppointmentService();

  List<DonationCenter> centers = [];
  DonationCenter? selectedCenter;
  bool isLoadingCenters = true;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      // --- 🌟 2. Pasar el flag al servicio 🌟 ---
      final fetchedCenters = await service.fetchCenters(isGuest: widget.isGuest);
      
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

  @override
  Widget build(BuildContext context) {
    if (isLoadingCenters) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.red, size: 60),
        const SizedBox(height: 20),
        const Text(
          "Selecciona tu centro de donación",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 300, 
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: centers.length,
            itemBuilder: (context, index) {
              final c = centers[index];
              return RadioListTile<DonationCenter>(
                title: Text("${c.name} – ${c.comuna}"),
                value: c,
                groupValue: selectedCenter,
                onChanged: (v) => setState(() => selectedCenter = v),
              );
            },
          ),
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
              onPressed: selectedCenter == null
                  ? null
                  : () {
                      widget.onNext({
                        'center': selectedCenter!.name,
                        'centerId': selectedCenter!.id,
                      });
                    },
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Siguiente"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customBlue[700],
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}