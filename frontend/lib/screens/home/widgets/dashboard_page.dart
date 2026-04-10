import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';


import '../../../colours/app_colors.dart';
import '../../admin/filtro_usuarios.dart';
import '../../campana/encuesta.dart';
import '../../campana/seleccionar_encuesta_screen.dart';
import '../../chat_asist/ChatAsistenteIA.dart';
import '../../map/map_screen.dart';
import '../../schedule/HistoryScreen.dart';
import '../../schedule/schedule_screen.dart';
import '../../trivia/pantallaSeleccion.dart';
import '../home_controller.dart';
import '../widgets/header.dart';
import '../widgets/section_title.dart';
import 'home_header.dart';

class HomeDashboardPage extends StatefulWidget {
  final bool showTrivia;
  const HomeDashboardPage({super.key, this.showTrivia = false});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  bool _isLoggedIn = false;
  String? _userName;
  final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      setState(() {
        _isLoggedIn = true;
        _userName =
            decoded['first_name'] ?? decoded['username'] ?? "Usuario";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left panel
                Expanded(
                  flex: 7,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight, // forces column to fill height
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 20),
                                const SectionTitle("Bienvenido a DonApp"),
                                const SizedBox(height: 10),
                                const Text(
                                  "DonApp te permite participar en campañas de donación, "
                                      "realizar trivias diarias, registrar tus donaciones y estar siempre informado.",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 30),

                                // Map + Agendar side by side
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SectionTitle("Mapa de Campañas Activas"),
                                          const SizedBox(height: 10),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: const SizedBox(
                                              height: 400,
                                              child: MapScreen(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_controller.isAdmin) ...[
                                            const SectionTitle("Notificaciones / Filtrar Usuarios"),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Container(
                                                height: 400,
                                                color: Colors.white,
                                                padding: const EdgeInsets.all(12),
                                                child: const FiltroUsuariosScreen(), // Your admin user filter widget
                                              ),
                                            ),
                                          ] else ...[
                                            const SectionTitle("Agendar Donación"),
                                            const SizedBox(height: 10),
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: const SizedBox(
                                                height: 400,
                                                child: ScheduleScreen(),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 30),

                                if (widget.showTrivia) ...[
                                  const SectionTitle("Trivia del Día"),
                                  const SizedBox(height: 10),
                                  const SizedBox(
                                    height: 250,
                                    child: NivelIntroScreen(),
                                  ),
                                  const SizedBox(height: 30),
                                ],

                                if (_isLoggedIn) ...[
                                  const SectionTitle("Encuesta Donante"),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: SizedBox(
                                      height: 280,
                                      child: Builder(
                                        builder: (context) {
                                          return Theme(
                                            data: ThemeData(
                                              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
                                              primaryColor: const Color(0xFFB20000),
                                              elevatedButtonTheme: ElevatedButtonThemeData(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF00AEEF),
                                                  foregroundColor: Colors.white,
                                                ),
                                              ),
                                            ),
                                            child: SeleccionarEncuestaScreen(),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                ],

                                const Spacer(),

                                // Footer
                                const Divider(height: 50, thickness: 1),
                                const Center(
                                  child: Text(
                                    "© 2025 DonApp - Todos los derechos reservados",
                                    style: TextStyle(color: Colors.black54, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Right panel: Chat (if logged in)
                if (_isLoggedIn)
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: Colors.grey.shade50,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 22,
                                backgroundImage: AssetImage('assets/images/avatar3.png'),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Hola, $_userName 👋",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Expanded(child: ChatAsistente()),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          )

        ],
      ),
    );
  }
}

