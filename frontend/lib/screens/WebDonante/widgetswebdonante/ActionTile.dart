import 'package:flutter/material.dart';

import '../../../colours/app_colors.dart';

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0), // Márgenes superior e inferior
      child: Material(
        color: Colors.transparent, // Hacemos transparente el color de fondo
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: _cardDecor(), // Fondo degradado
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Imagen de donante a la izquierda
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.customBlue[50], // Fondo azul claro para la imagen
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/images/blood_drop_character.png',
                    width: 40,
                    height: 40,
                  ), // Cambia la ruta de la imagen
                ),
                const SizedBox(width: 10),
                // Título de la acción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "¡Haz tu donación!", // Título
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brightGrey, // Cambia al color que prefieras
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label, // Texto adicional
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brightGrey, // Cambia al color que prefieras
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecor() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.xp, AppColors.streak], // Degradado de púrpura a rojo
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }
}
