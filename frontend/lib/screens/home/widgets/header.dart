import 'package:flutter/material.dart';
import '../../../colours/app_colors.dart';

class Header extends StatelessWidget {
  final String name;
  const Header(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/icon.png', height: 40),
        const SizedBox(width: 12),
        Text(
          "Bienvenido $name",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ],
    );
  }
}
