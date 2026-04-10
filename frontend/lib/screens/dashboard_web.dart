import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:donapp_android/screens/home_screen.dart'; // tu layout móvil
import 'WebDonante/Donante_home_screen.dart'; // tu nuevo layout web

/// Decide automáticamente entre mobile y web layout para la ruta '/home'
class DashboardRoot extends StatelessWidget {
  const DashboardRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    if (kIsWeb || isWideScreen) {
      // 🖥️ Web layout
      return const DonorDashboardPage();
    } else {
      // 📱 Mobile layout
      return const HomeScreen();
    }
  }
}
