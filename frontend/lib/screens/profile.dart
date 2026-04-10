// lib/screens/Usuario/profile.dart

import 'package:donapp_android/services/session_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/screens/edit_profile.dart';
import 'package:donapp_android/screens/formatFecha.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:donapp_android/screens/Usuario/getlevel.dart';
import 'package:donapp_android/screens/Usuario/otorgar_logro.dart';
import 'package:donapp_android/screens/Usuario/Amistad.dart';
import 'package:donapp_android/screens/Usuario/amistades_screen.dart';
import 'package:donapp_android/screens/Usuario/metricas_screen.dart';
import 'Usuario/logros.dart';
import 'avatar/avatar_model.dart';
import 'avatar/avatar_preview.dart';
import 'avatar/avatar_service.dart';
// Importamos la pantalla de Ajustes
import 'package:donapp_android/screens/settings_screen.dart'; 
// Importamos los colores primarios para acentos
import 'package:donapp_android/colours/app_colors.dart';


class PerfilUsuario extends StatefulWidget {
  const PerfilUsuario({super.key});

  @override
  State<PerfilUsuario> createState() => _PerfilUsuarioState();
}

class _PerfilUsuarioState extends State<PerfilUsuario> {
  User? _user;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isGuestUser = false; 
  AvatarData? _avatar;
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _checkUserStatus(); 
  }

  Future<void> _checkUserStatus() async {
    final isGuest = await SessionManager.isGuest();
    if (mounted) {
      setState(() {
        _isGuestUser = isGuest;
        _isLoading = false; 
      });

      if (!isGuest) {
        await _fetchUserData();
        await _fetchFriends();
        await _loadAvatar();
      }
    }
  }

  Future<void> _loadAvatar() async {
    final loaded = await AvatarService.load();
    if (!mounted) return;
    setState(() => _avatar = loaded);
  }

  Future<User?> fetchUserDetails() async {
    final String detailUrl = ApiConfig.endpoint("api/users/me/");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) return null;
      final response = await http.get(
        Uri.parse(detailUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final datos = jsonDecode(response.body);
        final nivel = datos['profile']['nivel'];
        if(mounted) {
          checkAndRequestLevelAchievement(context, nivel);
        }
        return User.fromJson(datos);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final user = await fetchUserDetails();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
        _errorMessage = user == null ? 'No se pudo cargar el usuario.' : '';
      });
    }
  }
  
  Future<void> _fetchFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token == null) return;
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint("api/users/friends/")),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200 && mounted) {
        setState(() => _friends = List<Map<String, dynamic>>.from(jsonDecode(response.body)));
      }
    } catch (e) {
      debugPrint("Error fetching friends: $e");
    }
  }

  Widget _buildGuestProfile() {
    // ▼▼▼ OBTENEMOS EL TEMA ▼▼▼
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_outlined, size: 80, color: theme.colorScheme.onSurfaceVariant), // Color de tema
              const SizedBox(height: 16),
              Text(
                'Únete a la comunidad',
                style: theme.textTheme.headlineSmall, // Estilo de tema
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Crea una cuenta para guardar tu progreso, ganar logros y conectar con otros donantes.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant), // Estilo de tema
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  SessionManager.clearSession();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                // El botón ya usa el ElevatedButtonTheme (¡bien!)
                child: const Text('Crear Cuenta o Iniciar Sesión', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              _buildSettingsButton(), // El botón de Ajustes
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isGuestUser) {
      return _buildGuestProfile();
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(body: Center(child: Text(_errorMessage)));
    }
    
    return Scaffold(
      // ▼▼▼ CORRECCIÓN ▼▼▼
      // Quitamos el fondo fijo para que el tema (oscuro/claro) funcione
      // backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildFriendList(),
              const SizedBox(height: 20),
              _buildSettingsButton(), // Botón de Ajustes
              const SizedBox(height: 10),
              _buildEditProfileButton(),
              const SizedBox(height: 10),
              _buildLogrosButton(),
              const SizedBox(height: 10),
              _buildFriendRequestsButton(),
              const SizedBox(height: 10),
              _buildMetricasButton(),
              const SizedBox(height: 10),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  // Botón de Ajustes (ahora consciente del tema)
  Widget _buildSettingsButton() {
    final theme = Theme.of(context);
    return Card(
      // La Card ya usa el CardThemeData (¡bien!)
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        // ▼▼▼ CORRECCIÓN ▼▼▼
        side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)), // Color de tema
      ),
      child: ListTile(
        leading: Icon(Icons.palette_outlined, color: theme.colorScheme.onSurfaceVariant), // Color de tema
        title: Text("Tema de la app", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)), // Color de tema
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant), // Color de tema
        onTap: () {
          Navigator.pushNamed(context, '/settings');
        },
      ),
    );
  }
  
  double _calculateProgress(int currentXp, int currentLevel) {
    final niveles = { 1: 0, 2: 50, 3: 120, 4: 200, 5: 300, 6: 450, 7: 600, 8: 800, 9: 1050, 10: 1400 };
    final xpNivelActual = niveles[currentLevel] ?? 0;
    final xpSiguienteNivel = niveles[currentLevel + 1];

    if (xpSiguienteNivel == null) return 1.0; // Nivel máximo
    if (xpSiguienteNivel <= xpNivelActual) return 0.0;

    final totalXpParaNivel = xpSiguienteNivel - xpNivelActual;
    final xpGanadoEnNivel = currentXp - xpNivelActual;
    
    return (xpGanadoEnNivel / totalXpParaNivel).clamp(0.0, 1.0);
  }

  Widget _buildFriendList() {
    final theme = Theme.of(context);
    return Card(
      // La Card ya usa el CardThemeData (¡bien!)
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Amigos", 
              // ▼▼▼ CORRECCIÓN ▼▼▼
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary), // Color de tema
            ),
            const SizedBox(height: 10),
            _friends.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("Aún no tienes amigos agregados", style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16))), // Color de tema
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _friends.length,
                    separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outline.withOpacity(0.5)), // Color de tema
                    itemBuilder: (context, index) {
                      final friend = _friends[index];
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: theme.colorScheme.primary, child: const Icon(Icons.person, color: Colors.white)), // Color de tema
                        title: Text(friend['username'] ?? 'N/A'), // El color de texto vendrá del tema
                        subtitle: Text('Nivel ${friend['nivel']}'), // El color de texto vendrá del tema
                        trailing: Icon(Icons.arrow_forward_ios, color: theme.colorScheme.onSurfaceVariant, size: 16), // Color de tema
                        onTap: () {
                          // Tu lógica de onTap no cambia
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileCard() {
    final theme = Theme.of(context); // Obtenemos el tema
    final profile = _user?.profile;
    final int currentXp = profile?.xp ?? 0;
    final int currentLevel = profile?.nivel ?? 1;
    final String levelName = profile?.nombreNivel ?? 'Donante Novato';
    final String fullName = (profile?.nombre?.isNotEmpty == true) ? profile!.nombre! : _user?.username ?? 'N/A';
    final niveles = { 1: 0, 2: 50, 3: 120, 4: 200, 5: 300, 6: 450, 7: 600, 8: 800, 9: 1050, 10: 1400 };
    final xpNivelActual = niveles[currentLevel] ?? 0;
    final xpNextLevel = niveles[currentLevel + 1];
    
    final String xpText;
    final double progress;

    if (xpNextLevel == null) {
      // Nivel máximo
      xpText = '$currentXp XP (Nivel Máximo)';
      progress = 1.0;
    } else {
      xpText = '$currentXp / $xpNextLevel XP';
      progress = _calculateProgress(currentXp, currentLevel);
    }
    final xpToNextLevel = (xpNextLevel != null) ? (xpNextLevel - currentXp) : 0;


    return Card(
      // La Card ya usa el CardThemeData (¡bien!)
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            Center(
              child: _avatar != null
                  ? AvatarPreview(data: _avatar!, size: 100)
                  : CircleAvatar(radius: 50, backgroundColor: theme.colorScheme.primaryContainer, child: Icon(Icons.person, size: 60, color: theme.colorScheme.onPrimaryContainer)), // Color de tema
            ),
            const SizedBox(height: 10),
            Text(
              fullName.trim().isNotEmpty ? fullName : _user?.username ?? 'N/A',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold), // Estilo de tema
            ),
            const SizedBox(height: 10),
            Text(
              'Nivel $currentLevel - $levelName', 
              style: theme.textTheme.titleMedium, // Estilo de tema
            ),
            const SizedBox(height: 8),
            Stack(
              clipBehavior: Clip.none, // Permite que el texto se salga si es necesario
              children: [
                Container(
                  height: 15,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: theme.colorScheme.surfaceVariant, // Color de tema
                  ),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.transparent, // El fondo ya lo da el Container
                    color: AppColors.primary, // Mantenemos el rojo para la barra
                    minHeight: 15,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      xpText,
                      style: TextStyle(
                        // ▼▼▼ CORRECCIÓN ▼▼▼
                        // Texto oscuro si el fondo es claro, o viceversa
                        color: theme.brightness == Brightness.light ? Colors.black54 : Colors.white70, 
                        fontWeight: FontWeight.bold,
                        fontSize: 10
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            if (xpToNextLevel > 0)
              Text('$xpToNextLevel XP para el siguiente nivel', style: theme.textTheme.bodySmall), // Estilo de tema
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard() {
    final profile = _user?.profile;
    return Card(
      // La Card ya usa el CardThemeData (¡bien!)
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          children: [
            _buildInfoRow(icon: Icons.person_outline, label: 'Sexo', value: profile?.sexo ?? 'N/A', valueColor: null),
            _buildDivider(),
            _buildInfoRow(icon: Icons.bloodtype, label: 'Tipo de Sangre', value: profile?.tipoSangre ?? 'N/A', valueColor: null),
            _buildDivider(),
            _buildInfoRow(
              icon: Icons.check_circle_outline,
              label: 'Estado de aptitud',
              value: (profile?.aptoParaDonar == true) ? 'Apto para donar' : (profile?.aptoParaDonar == false ? 'No apto' : 'N/A'),
              // Dejamos que los colores de "apto" sean fijos (semántica)
              valueColor: (profile?.aptoParaDonar == true) ? Colors.green : Colors.red,
            ),
            _buildDivider(),
            _buildInfoRow(icon: Icons.calendar_today, label: 'Última donación', value: formatFecha(profile?.fechaUltimaDonacion), valueColor: null),
            _buildDivider(),
            _buildInfoRow(icon: Icons.calendar_today_outlined, label: 'Próxima donación', value: formatFecha(profile?.proximaDonacion), valueColor: null),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String? value, Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary), // Mantenemos el rojo como color de acento
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)), // Color de tema
          const Spacer(),
          Text(
            value ?? 'N/A', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              // ▼▼▼ CORRECCIÓN ▼▼▼
              // Usa el color pasado (verde/rojo) o el color de texto por defecto del tema
              color: valueColor ?? theme.colorScheme.onSurface 
            ),
          ),
        ],
      ),
    );
  }

  // ▼▼▼ CORRECCIÓN ▼▼▼
  Widget _buildDivider() { return Divider(height: 20, thickness: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.3)); }
  
  Widget _buildEditProfileButton() {
    return SizedBox(
      width: double.infinity,
      // ▼▼▼ CORRECCIÓN ▼▼▼
      // ElevatedButton se adapta mejor al tema que OutlinedButton
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EditProfileScreen()),
          ).then((value) {
            if (value == true) _fetchUserData();
          });
        },
        icon: const Icon(Icons.edit_outlined),
        label: const Text("Editar perfil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          // El ElevatedButtonTheme ya lo estiliza (¡bien!)
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
  
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          SessionManager.clearSession();
          if (!mounted) return;
          // Usamos pushNamedAndRemoveUntil para limpiar la pila de navegación
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
        },
        icon: const Icon(Icons.logout),
        label: const Text("Cerrar sesión", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          // ▼▼▼ CORRECCIÓN ▼▼▼
          // Hacemos que el botón de logout use el color "error" del tema
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error, width: 2), 
          padding: const EdgeInsets.symmetric(vertical: 16), 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        ),
      ),
    );
  }

  Widget _buildLogrosButton() {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
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
      width: double.infinity,
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
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MetricasScreen())),
        icon: Icon(Icons.bar_chart, color: Colors.orange.shade400), // Mantenemos un color distintivo
        label: Text("Mis métricas", style: TextStyle(fontSize: 18, color: Colors.orange.shade400, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.orange.shade400, width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
    );
  }
}