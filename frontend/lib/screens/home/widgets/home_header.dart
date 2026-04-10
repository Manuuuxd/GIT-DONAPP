import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import '../home_controller.dart';

class HomeHeader extends StatelessWidget {
  final HomeController controller;
  const HomeHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.customBlue, Color(0xFF4AB5E3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('assets/images/icon.png', height: 40),
          const SizedBox(width: 12),
          const Text(
            'DonApp Dashboard',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22),
          ),
          const Spacer(),
          if (controller.isLoggedIn) ...[
            Text(
              controller.userName ?? "Usuario",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            const CircleAvatar(
              backgroundImage:
              AssetImage('assets/images/avatar3.png'),
              radius: 20,
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.login, size: 18),
              label: const Text("Iniciar sesión"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.customBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
        ],
      ),
    );
  }
}
