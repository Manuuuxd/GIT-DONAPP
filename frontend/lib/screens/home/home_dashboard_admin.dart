import 'package:flutter/material.dart';
import 'package:donapp_android/screens/estadisticas_camp/stats_page.dart';
import 'package:donapp_android/screens/campanias/crear_campania_screen.dart';
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/screens/chat_asist/ChatAsistenteIA.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeDashboardAdmin extends StatefulWidget {
  const HomeDashboardAdmin({super.key});

  @override
  State<HomeDashboardAdmin> createState() => _HomeDashboardAdminState();
}

class _HomeDashboardAdminState extends State<HomeDashboardAdmin> {
  int _selectedIndex = 0;
  String? jwtToken; // Store token here
  bool _isLoading = true; // For loading state

  late List<Widget> pages; // Will initialize after loading token

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    jwtToken = prefs.getString('authToken');

    // Now we can initialize pages
    pages = [
      const StatsShell(),
      if (jwtToken != null) CrearCampaniaScreen(jwtToken: jwtToken!),
      FiltroUsuariosScreen(),
      const ChatAsistente(),
    ];

    setState(() {
      _isLoading = false; // Stop loading
    });
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final destinations = const [
      NavigationRailDestination(
        icon: Icon(Icons.bar_chart_outlined),
        label: Text('Estadísticas'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.add_circle_outline),
        label: Text('Crear Campaña'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_alt_outlined),
        label: Text('Usuarios'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: Text('Chat'),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: destinations,
            backgroundColor: Colors.white,
            selectedIconTheme:
            const IconThemeData(color: AppColors.customBlue, size: 28),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
