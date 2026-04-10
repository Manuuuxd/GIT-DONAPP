// lib/screens/admin/admin_dashboard_root.dart

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart'; // <- 📱 TU VISTA MÓVIL (NO SE TOCA)
import 'admin_dashboard_web.dart';    // <- 🖥️ LA NUEVA VISTA WEB

class AdminDashboardRoot extends StatelessWidget {
  const AdminDashboardRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Revisa si es web o una pantalla ancha (como una tablet)
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    if (kIsWeb || isWideScreen) {
      // 🖥️ Muestra el nuevo Dashboard Web para Marketing (HU79A)
      return const AdminDashboardWeb();
    } else {
      // 📱 Muestra el Dashboard Móvil que ya tenías
      return const AdminDashboardScreen();
    }
  }
}