import 'package:flutter/material.dart';
import 'package:donapp_android/screens/campanias/campanias_screen.dart';
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:donapp_android/colours/app_colors.dart';

class HomeLanding extends StatelessWidget {
  const HomeLanding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "DonApp Web",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.customBlue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Únete a la red de donadores altruistas. Explora campañas activas y sé parte del cambio.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            SizedBox(height: 400, child: MapScreen()),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customBlue,
                padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Inicia Sesión para Participar",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
