// lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa SÓLO las pantallas de ADMIN
// import 'package:donapp_android/screens/chat_asist/ChatAsistenteIA.dart'; // <-- ELIMINADO
import 'package:donapp_android/screens/admin/filtro_usuarios.dart';
import 'package:donapp_android/screens/estadisticas_camp/stats_page.dart';
import 'package:donapp_android/screens/campanias/crear_campania_screen.dart';
import 'package:donapp_android/screens/campanias/campanias_screen.dart';
import 'package:donapp_android/screens/campana/encuesta.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ya no necesitamos 'colorTitle', usaremos el tema
    // final colorTitle = AppColors.customBlue;

    return Scaffold(
      // El color de fondo ahora lo maneja el AppTheme
      // backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Dashboard de Gestión"),
        // Eliminamos los colores hardcodeados. El AppTheme se encarga.
        // backgroundColor: AppColors.customBlue.withOpacity(0.05),
        // elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _HeaderCard(), // Este widget ahora es theme-aware
            const SizedBox(height: 24),

            _SectionTitle('Acciones de Gestión'), // Ya no pasamos color
            const SizedBox(height: 20),

            GridView.count(
              crossAxisCount: 2, 
              childAspectRatio: 1.2, 
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16, 
              children: [
                // _ActionTile(icon: Icons.chat_bubble_rounded, label: 'Chat Agente IA', onTap: () => _go(context, const ChatAsistente())), // <-- ELIMINADO
                _ActionTile(icon: Icons.filter_alt_rounded, label: 'Filtro de Usuarios', onTap: () => _go(context, const FiltroUsuariosScreen())),
                _ActionTile(icon: Icons.bar_chart_rounded, label: 'Estadísticas', onTap: () => _go(context, const StatsShell())),
                _ActionTile(
                  icon: Icons.add_circle_rounded,
                  label: 'Crear Campaña',
                  onTap: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final jwtToken = prefs.getString('authToken');
                    if (jwtToken != null) {
                      // ignore: use_build_context_synchronously
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CrearCampaniaScreen(jwtToken: jwtToken)),
                      );
                    }
                  },
                ),
                _ActionTile(icon: Icons.list_alt_rounded, label: 'Listado Campañas', onTap: () => _go(context, const CampaniasScreen())),
                _ActionTile(icon: Icons.assignment_rounded, label: 'Encuestas', onTap: () => _go(context, EncuestaApp())),
                
                // Botón de Ajustes
                _ActionTile(
                  icon: Icons.palette_outlined,
                  label: 'Ajustes de Tema',
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

/* ---------------- UI Elements (AHORA THEME-AWARE) ---------------- */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema actual (claro u oscuro)
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Definimos colores dinámicos
    final cardColor = isDark ? const Color(0xFF3A2E2E) : const Color(0xFFFFF0E5);
    final titleColor = isDark ? Colors.orange.shade100 : Colors.deepOrange.shade800;
    final subtitleColor = isDark ? Colors.orange.shade200.withOpacity(0.8) : Colors.deepOrange.shade700;

    final horizontalPadding = MediaQuery.of(context).size.width > 380 ? 24.0 : 16.0;
    final verticalPadding = MediaQuery.of(context).size.width > 380 ? 24.0 : 20.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      decoration: BoxDecoration(
        color: cardColor, // <-- USA EL COLOR DINÁMICO
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/blood_drop_character.png', 
            width: 70, 
            height: 70,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido Encargado 👋',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: titleColor, // <-- USA EL COLOR DINÁMICO
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Gestiona campañas, usuarios y revisa estadísticas.',
                  style: TextStyle(
                    fontSize: 14, 
                    color: subtitleColor, // <-- USA EL COLOR DINÁMICO
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

class _SectionTitle extends StatelessWidget {
  final String text;
  // Ya no pasamos el color
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        // Obtenemos el color primario del tema
        color: Theme.of(context).colorScheme.primary, 
        fontWeight: FontWeight.bold, 
        fontSize: 18
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Obtenemos los colores del tema
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        // El 'Card' ya usa el 'cardTheme' que definimos en app_theme.dart
        // por lo que su color (blanco o gris oscuro) es automático.
        elevation: 2, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0), 
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 32, 
                // Usamos el color primario del tema
                color: theme.colorScheme.primary 
              ),
              const SizedBox(height: 12),
              Text(
                label, 
                textAlign: TextAlign.center, 
                style: TextStyle(
                  fontWeight: FontWeight.w600, 
                  fontSize: 14,
                  // Usamos el color de texto 'onSurface' del tema
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}