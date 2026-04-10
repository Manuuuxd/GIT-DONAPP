import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import '../../campanias/crear_campania_screen.dart';
import '../../admin/filtro_usuarios.dart';
import '../../campana/encuesta.dart';
import '../../map/map_screen.dart';
import 'admin_button.dart';

class AdminPanel extends StatelessWidget {
  final void Function(Widget screen) onOpenDialog;
  const AdminPanel({super.key, required this.onOpenDialog});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              left: BorderSide(color: Colors.grey.shade300)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(-3, 0))
          ],
        ),
        padding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Panel de Herramientas",
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            AdminButton(
              icon: Icons.add_circle,
              text: "Crear Campaña",
              color: AppColors.orange,
              onTap: () => onOpenDialog(
                  const CrearCampaniaScreen(jwtToken: "mock-token")),
            ),
            AdminButton(
              icon: Icons.people,
              text: "Filtrar Usuarios",
              color: AppColors.customBlue,
              onTap: () => onOpenDialog(const FiltroUsuariosScreen()),
            ),
            AdminButton(
              icon: Icons.assignment,
              text: "Encuesta Donante",
              color: Colors.teal,
              onTap: () => onOpenDialog(EncuestaApp()),
            ),
          ],
        ),
      ),
    );
  }
}
