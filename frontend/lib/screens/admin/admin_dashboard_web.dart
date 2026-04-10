// lib/screens/admin/admin_dashboard_web.dart (MODIFICADO)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa los nuevos widgets
import 'package:donapp_android/screens/admin/widgets/admin_sidebar_web.dart';
import 'package:donapp_android/screens/admin/widgets/admin_header_web.dart';

// Importa todas las pantallas de admin
import 'package:donapp_android/screens/chat_asist/ChatAsistenteIA.dart';
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/screens/estadisticas_camp/stats_page.dart';
import 'package:donapp_android/screens/campanias/crear_campania_screen.dart';
import 'package:donapp_android/screens/campanias/campanias_screen.dart';
import 'package:donapp_android/screens/campana/encuesta.dart';
import 'package:donapp_android/screens/settings_screen.dart';

class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({super.key});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  int _selectedIndex = 0;
  String? _jwtToken;
  bool _isLoading = true;

  late final List<Widget> _pages;
  late final List<NavigationRailDestination> _destinations;
  late final List<String> _pageTitles; // Para el título del header

  @override
  void initState() {
    super.initState();
    _loadTokenAndSetupPages();
  }

  Future<void> _loadTokenAndSetupPages() async {
    final prefs = await SharedPreferences.getInstance();
    _jwtToken = prefs.getString('authToken');

    // Define las páginas que se mostrarán en el IndexedStack
    _pages = [
      const StatsShell(),          
      const CampaniasScreen(),     
      if (_jwtToken != null)
        CrearCampaniaScreen(jwtToken: _jwtToken!)
      else
        const Center(child: Text("Error al cargar token para crear campaña")),
      const FiltroUsuariosScreen(),
      EncuestaApp(),
      const ChatAsistente(),
      const SettingsScreen(),      
    ];

    // Define los botones de la barra lateral (AHORA SÓLO ICONOS)
    _destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: Text('Dashboard'), // Texto para accesibilidad
      ),
      NavigationRailDestination(
        icon: Icon(Icons.bar_chart_outlined),
        selectedIcon: Icon(Icons.bar_chart_rounded),
        label: Text('Estadísticas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt_rounded),
        label: Text('Campañas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.add_circle_outline_rounded),
        selectedIcon: Icon(Icons.add_circle_rounded),
        label: Text('Crear Campaña'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.filter_alt_outlined),
        selectedIcon: Icon(Icons.filter_alt_rounded),
        label: Text('Usuarios'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assignment_outlined),
        selectedIcon: Icon(Icons.assignment_rounded),
        label: Text('Encuestas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: Icon(Icons.chat_bubble_rounded),
        label: Text('Chat IA'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.palette_outlined),
        selectedIcon: Icon(Icons.palette_rounded),
        label: Text('Tema'),
      ),
    ];

    // Títulos para el encabezado (correspondientes a las páginas)
    _pageTitles = const [
      'Dashboard',
      'Estadísticas',
      'Campañas',
      'Crear Campaña',
      'Gestión de Usuarios',
      'Encuestas',
      'Asistente de Chat',
      'Configuración de Tema',
    ];


    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          // 1. Barra lateral izquierda (AdminSidebarWeb)
          AdminSidebarWeb(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: _destinations,
          ),
          
          // Divisor entre la sidebar y el contenido principal
          const VerticalDivider(thickness: 1, width: 1, color: Colors.grey),

          // 2. Columna principal para el Header y el Contenido
          Expanded(
            child: Column(
              children: [
                // 3. Encabezado superior (AdminHeaderWeb)
                AdminHeaderWeb(title: _pageTitles[_selectedIndex]),
                
                // Divisor debajo del header
                const Divider(height: 1, thickness: 1, color: Colors.grey),

                // 4. Contenido principal (la página seleccionada)
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.background, // Fondo claro para el contenido
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: _pages,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}