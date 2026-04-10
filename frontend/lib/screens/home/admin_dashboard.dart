import 'package:donapp_android/screens/campana/encuesta.dart';
import 'package:donapp_android/screens/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:donapp_android/screens/estadisticas_camp/stats_page.dart';
import 'package:donapp_android/screens/campanias/crear_campania_screen.dart';
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/screens/chat_asist/ChatAsistenteIA.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../campanias/campanias_screen.dart';
import 'home_controller.dart';




class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;

  // Lista de páginas para admin
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const CampaniasScreen(),      // Crear / ver campañas
      const StatsShell(),           // Estadísticas
      FiltroUsuariosScreen(),       // Filtrar usuarios
      EncuestaApp(),  // Crear encuestas
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navDestinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.campaign_outlined),
        selectedIcon: Icon(Icons.campaign),
        label: Text('Campañas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart),
        label: Text('Estadísticas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.filter_alt_outlined),
        selectedIcon: Icon(Icons.filter_alt),
        label: Text('Usuarios'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment),
        label: Text('Encuestas'),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            elevation: 3,
            destinations: navDestinations,
            selectedIconTheme: const IconThemeData(
                color: AppColors.customBlue, size: 28),
            unselectedIconTheme: const IconThemeData(
                color: Colors.black54, size: 26),
          ),

          // Panel principal
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Header
                HomeHeader(controller: HomeController()),

                // Contenido
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _pages[_selectedIndex],
                  ),
                ),

                // Chat al final del dashboard
                SizedBox(
                  height: 300, // Ajusta tamaño del chat
                  child: const ChatAsistente(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
