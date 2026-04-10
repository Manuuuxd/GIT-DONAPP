import 'dart:convert';

import 'package:donapp_android/screens/WebDonante/games_screen.dart';
import 'package:donapp_android/screens/WebDonante/perfil_donante.dart';
import 'package:donapp_android/screens/WebDonante/schedule_web.dart';
import 'package:donapp_android/screens/WebDonante/widgetswebdonante/Headerweb.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'package:donapp_android/screens/map/map_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../../CONFIG/api_config.dart';
import '../Usuario/getlevel.dart';
import '../Usuario/user_model.dart';
import '../campanias/campanias_screen.dart';
import '../home/home_controller.dart';
import '../home/widgets/home_header.dart';
import 'gamificacion.dart';

class DonorDashboardPage extends StatefulWidget {
  final dynamic controller;

  const DonorDashboardPage({super.key, this.controller});

  @override
  State<DonorDashboardPage> createState() => _DonorDashboardPageState();
}
Future<Map<String, String>> fetchDonorData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  if (token == null) {
    return {
      'nombre': 'Donante invitado',
      'email': '',
      'rut': '',
    };
  }

  final url = ApiConfig.endpoint("api/users/me/");
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'nombre': data['first_name'] ?? data['username'] ?? 'Donante',
        'email': data['email'] ?? '',
        'rut': data['rut'] ?? '',
      };
    } else {
      return {
        'nombre': 'Donante',
        'email': '',
        'rut': '',
      };
    }
  } catch (e) {
    debugPrint("Error al obtener datos del donante: $e");
    return {
      'nombre': 'Donante',
      'email': '',
      'rut': '',
    };
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Escalas dinámicas (ajustan tamaños según el ancho)
        final isLarge = screenWidth > 900; // Pantallas grandes
        final imageSize = isLarge ? 120.0 : screenWidth * 0.18;
        final titleFontSize = isLarge ? 28.0 : screenWidth * 0.045;
        final subtitleFontSize = isLarge ? 18.0 : screenWidth * 0.035;
        final horizontalPadding = screenWidth * 0.08;
        final verticalPadding = screenHeight * 0.02;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 20),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: _cardDecor(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Imagen del donante (más grande en pantallas amplias)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/blood_drop_character.png',
                        width: imageSize,
                        height: imageSize * 1.2,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Título y subtítulo
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "¡Haz tu donación!",
                            style: TextStyle(
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brightGrey,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brightGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  BoxDecoration _cardDecor() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.xp, AppColors.streak], // Degradado de púrpura a rojo
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    );
  }
}


class _DonorDashboardPageState extends State<DonorDashboardPage> {
  final HomeController controller = HomeController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    controller.loadUserData(context).then((_) {
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }


    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // ✅ Reemplazamos AppBar por tu header personalizado
      body: Stack( // Usamos Stack para superponer el fondo animado
        children: [
          // Fondo animado (MascotaImage)
          //MascotaImage(),
      Column(
        children: [

          HomeHeaderweb(controller: controller), // <-- Header con gradiente

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ActionTile(
                icon: Icons.bloodtype, // Cambia el icono según lo que desees
                label: "Agenda tu donación",
                onTap: () {
                  // Acción cuando se toca el tile
                  print('Donación agendada');
                },
              ),
                // --- Fila con agendamiento + mapa ---
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🩸 Agenda
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🩸 Agenda tu próxima donación",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.customRed,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ScheduleScreenweb(
                                  fetchDonorData: fetchDonorData(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // 🗺️ Mapa
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "🗺️ Puntos cercanos de donación",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.customRed,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 450,
                                width: double.infinity,
                                child: IgnorePointer(
                                  ignoring: false,
                                  child: const MapScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                const GamesScreen(),

              ],
            ),
          ),
        ],
      ),
        ]
      )
    );
  }

  Widget _buildGamificationStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard("Nivel", "3 🧬"),
        _buildStatCard("Donaciones", "4/10"),
        _buildStatCard("XP", "2300 ⭐"),
      ],
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
