import 'dart:convert';
import 'package:donapp_android/screens/WebDonante/widgetswebdonante/Headerweb.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/screens/avatar/avatar_model.dart';
import 'package:donapp_android/screens/avatar/avatar_preview.dart';
import 'package:donapp_android/screens/avatar/avatar_service.dart';
import 'package:donapp_android/screens/formatFecha.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:donapp_android/screens/edit_profile.dart';
import '../../colours/app_colors.dart';
import '../Usuario/amistades_screen.dart';
import '../Usuario/logros.dart';
import '../Usuario/metricas_screen.dart';
import '../home/home_controller.dart';

class PerfilUsuarioModern extends StatefulWidget {
  const PerfilUsuarioModern({super.key});

  @override
  State<PerfilUsuarioModern> createState() => _PerfilUsuarioModernState();
}

class _PerfilUsuarioModernState extends State<PerfilUsuarioModern> {
  final HomeController controller = HomeController();
  User? _user;
  AvatarData? _avatar;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentSection; // "logros", "amistades", "metricas"

  void _showSection(String section) {
    setState(() {
      _currentSection = section;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await controller.loadUserData(context);
    await _fetchUserAndAvatar();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchUserAndAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("No hay token guardado");

      // --- Llamada a /api/users/me/ ---
      final userRes = await http.get(
        Uri.parse(ApiConfig.endpoint("api/users/me/")),
        headers: {"Authorization": "Bearer $token"},
      );

      if (userRes.statusCode != 200) {
        throw Exception("Error al obtener usuario (${userRes.statusCode})");
      }

      final userData = jsonDecode(userRes.body);
      final user = User.fromJson(userData);
      final avatar = await AvatarService.load();

      if (!mounted) return;
      setState(() {
        _user = user;
        _avatar = avatar;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    }
  }

  double _calculateProgress(int currentXp, int currentLevel) {
    final niveles = {
      1: 0, 2: 50, 3: 120, 4: 200, 5: 300,
      6: 450, 7: 600, 8: 800, 9: 1050, 10: 1400
    };
    final xpActual = niveles[currentLevel] ?? 0;
    final xpSiguiente = niveles[currentLevel + 1] ?? xpActual;
    if (xpSiguiente <= xpActual) return 1.0;
    return (currentXp - xpActual) / (xpSiguiente - xpActual);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(child: Text("Error: $_errorMessage")),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("No se encontraron datos del usuario.")),
      );
    }

    final profile = _user!.profile;
    final xp = profile?.xp ?? 0;
    final nivel = profile?.nivel ?? 1;
    final progress = _calculateProgress(xp, nivel);
    final fullName = profile?.nombre ?? _user?.username ?? "Donante";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HomeHeaderweb(controller: controller),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: const [
                    Icon(Icons.person_outline,
                        color: AppColors.xp, size: 28),
                    SizedBox(width: 8),
                    Text(
                      "Perfil del Donante",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Avatar + info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _avatar != null
                        ? AvatarPreview(data: _avatar!, size: 100)
                        : CircleAvatar(
                      radius: 45,
                      backgroundColor: AppColors.secondary[50],
                      child: const Icon(Icons.person,
                          size: 50, color: AppColors.white),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground)),
                          Text(profile?.nombreNivel ?? "Donante Novato",
                              style: const TextStyle(
                                  fontSize: 16, color: AppColors.textMuted)),
                          const SizedBox(height: 16),
                          const Text("Progreso del nivel",
                              style: TextStyle(color: AppColors.textMuted)),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 14,
                              backgroundColor: AppColors.secondary[500],
                              valueColor: AlwaysStoppedAnimation(AppColors.xp),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("$xp XP  |  Nivel $nivel",
                              style: const TextStyle(color: AppColors.xp)),
                        ],
                      ),


                    ),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildLogrosButton(),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildFriendRequestsButton(),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: _buildMetricasButton(),
                    ),

                  ],


                ),

                const SizedBox(height: 32),
                const Text(
                  "Información de cuenta",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.xp,
                  ),
                ),
                const SizedBox(height: 16),

                _infoField("Correo", _user?.email ?? "N/A"),
                _infoField("Tipo de sangre", profile?.tipoSangre ?? "N/A"),
                _infoField("Última donación",
                    formatFecha(profile?.fechaUltimaDonacion)),
                _infoField("Próxima donación",
                    formatFecha(profile?.proximaDonacion)),

                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EditProfileScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                    ),
                    icon: const Icon(Icons.edit, color: AppColors.white),
                    label: const Text("Editar perfil",
                        style: TextStyle(fontSize: 16, color: AppColors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _infoField(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface, // fondo claro de tarjeta
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderOutline, // borde sutil
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted, // texto gris suave
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.onBackground, // texto principal
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildLogrosButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 300,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            // Reemplazamos la ruta por la de Insignias
            MaterialPageRoute(builder: (_) => const LogrosScreen()),
          );
        },
        icon: Icon(Icons.emoji_events, color: theme.colorScheme.secondary), // Color de tema
        label: Text(
          "Ver Logros",
          style: TextStyle(
            fontSize: 18,
            color: theme.colorScheme.secondary, // Color de tema
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.colorScheme.secondary, width: 2), // Color de tema
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendRequestsButton() {
    return SizedBox(
      width: 300,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AmistadesScreen())),
        icon: Icon(Icons.group_add, color: Colors.blue.shade400), // Mantenemos un color distintivo
        label: Text("Solicitudes de amistad", style: TextStyle(fontSize: 18, color: Colors.blue.shade400, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.blue.shade400, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }

  Widget _buildMetricasButton() {
    return SizedBox(
      width: 300,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MetricasScreen())),
        icon: Icon(Icons.bar_chart, color: Colors.orange.shade400), // Mantenemos un color distintivo
        label: Text("Mis métricas", style: TextStyle(fontSize: 18, color: Colors.orange.shade400, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.orange.shade400, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}
