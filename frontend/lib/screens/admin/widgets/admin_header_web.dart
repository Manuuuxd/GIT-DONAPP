// lib/screens/admin/widgets/admin_header_web.dart

import 'package:flutter/material.dart';

class AdminHeaderWeb extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AdminHeaderWeb({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.background, // Fondo claro como el body
      elevation: 0, // Sin sombra
      title: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      actions: [
        const SizedBox(width: 20),
        // Avatar del usuario
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface, // Fondo del avatar
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: const AssetImage('assets/images/avatar1.png'), // Tu imagen de avatar
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                radius: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Donante Prueba', // Nombre del usuario
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}