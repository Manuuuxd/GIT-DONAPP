// lib/screens/home_screen.dart

import 'package:donapp_android/screens/HomeBodyScreen.dart';
import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart'; // Para tu color primario
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:donapp_android/screens/schedule/schedule_screen.dart';
import 'package:donapp_android/screens/Usuario/amistades_screen.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeBodyScreen(), // 0: Inicio
    const MapScreen(), // 1: Mapa
    const AmistadesScreen(), // 2: Amigos
    const PerfilUsuario(), // 3: Mi perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: _screens[_currentIndex], 
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleScreen()));
        },
        backgroundColor: AppColors.primary, 
        shape: const CircleBorder(),
        child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
        elevation: 2.0,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), 
        notchMargin: 8.0, 
        color: theme.colorScheme.surface, 
        elevation: 10, 
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Inicio',
                isSelected: _currentIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
              _BottomNavItem(
                icon: Icons.map_rounded,
                label: 'Mapa',
                isSelected: _currentIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
              const SizedBox(width: 40), 
              _BottomNavItem(
                icon: Icons.group_rounded,
                label: 'Amigos',
                isSelected: _currentIndex == 2,
                onTap: () => _onItemTapped(2),
              ),
              _BottomNavItem(
                icon: Icons.person_rounded,
                label: 'Mi perfil',
                isSelected: _currentIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget personalizado para los ítems de la barra de navegación
class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.6);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          // ▼▼▼ ¡AQUÍ ESTÁ LA CORRECCIÓN! ▼▼▼
          // Reducimos el padding vertical de 8.0 a 4.0 para ahorrar espacio.
          padding: const EdgeInsets.symmetric(vertical: 4.0), 
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}