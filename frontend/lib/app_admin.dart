// lib/app_admin.dart (MODIFICADO)

import 'package:flutter/material.dart';
// Importa la pantalla de login de admin
import 'package:donapp_android/screens/admin/admin_login_screen.dart'; 

import 'package:donapp_android/screens/settings_screen.dart';

// --- 🌟 CAMBIO AQUÍ 🌟 ---
// 1. Importa el NUEVO selector de layout
import 'package:donapp_android/screens/admin/admin_dashboard_root.dart'; 
// --- FIN CAMBIO ---

import 'package:provider/provider.dart';
import 'package:donapp_android/providers/theme_provider.dart';
import 'package:donapp_android/colours/app_theme.dart';

class AppAdmin extends StatelessWidget {
  const AppAdmin({super.key});

  @override
  Widget build(BuildContext context) {

    final themeProvider = Provider.of<ThemeProvider>(context);


    return MaterialApp(
      title: 'DonApp (Admin)',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      // Inicia en la pantalla de Login de Admin
      home: const AdminLoginScreen(),

      routes: {
        '/settings': (_) => const SettingsScreen(),

        // --- 🌟 CAMBIO AQUÍ 🌟 ---
        // 2. La ruta '/dashboard' ahora apunta al "selector"
        // que decidirá si mostrar la app móvil o la web.
        '/dashboard': (_) => const AdminDashboardRoot(),
        // --- FIN CAMBIO ---
      },
    );
  }
}