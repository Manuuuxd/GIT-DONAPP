// lib/screens/admin/widgets/admin_sidebar_web.dart (CORREGIDO)

import 'package:flutter/material.dart';

class AdminSidebarWeb extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationRailDestination> destinations;

  const AdminSidebarWeb({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.none, // No mostrar texto por defecto
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          children: [
            // Logo de la App
            Image.asset(
              'assets/images/Icono.png', // Asegúrate de que esta ruta sea correcta
              height: 40,
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            // Sección "MENU" como en la imagen
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Text(
                  'MENU',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      groupAlignment: -1.0, // Alinea el contenido a la parte superior
      destinations: destinations,
      selectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onPrimary, // Icono blanco en fondo de color
        size: 26,
      ),
      unselectedIconTheme: IconThemeData(
        color: Theme.of(context).colorScheme.onSurfaceVariant, // Icono gris oscuro
        size: 24,
      ),
      selectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      // Estilo del indicador del elemento seleccionado
      indicatorColor: Theme.of(context).colorScheme.primary, // Color de fondo del elemento seleccionado
      backgroundColor: Theme.of(context).colorScheme.surface, // Fondo blanco de la barra lateral
      
      // --- 🌟 CAMBIO AQUÍ 🌟 ---
      // elevation: 0, // <-- Esta línea causaba el error y fue eliminada
      // --- FIN CAMBIO ---

      minWidth: 70, // Ancho mínimo para los iconos
      extended: false, // Inicia colapsada, solo con iconos
    );
  }
}