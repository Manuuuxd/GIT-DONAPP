import 'package:flutter/material.dart';
import 'logros_model.dart'; // Asegúrate que la ruta a tu modelo sea correcta
import 'package:donapp_android/CONFIG/api_config.dart'; // Asumo que esta es tu configuración
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Tu función para consumir la API (sin cambios)
Future<List<Achievement>> fetchAchievements(String token) async {
  final String url = ApiConfig.endpoint('api/logros/user-achievements/');
  try {
    if (token.isEmpty) return [];
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      // Forzamos la decodificación como UTF-8 para evitar problemas con tildes y caracteres especiales
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      print('Logros cargados: $data');
      return data.map((json) => Achievement.fromJson(json)).toList();
    } else {
      print('Error cargando logros: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('Excepción al cargar logros: $e');
    return [];
  }
}

class LogrosScreen extends StatefulWidget {
  const LogrosScreen({Key? key}) : super(key: key);

  @override
  State<LogrosScreen> createState() => _LogrosScreenState();
}

class _LogrosScreenState extends State<LogrosScreen> {
  late Future<List<Achievement>> futureAchievements;

  @override
  void initState() {
    super.initState();
    futureAchievements = _loadAchievements();
  }

  Future<List<Achievement>> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    return fetchAchievements(token);
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Obtenemos el tema ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
      appBar: AppBar(
        title: const Text('Mis Logros'),
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        elevation: 1, // <-- (Opcional) leve elevación
        foregroundColor: colorScheme.onBackground, // <-- Cambio
      ),
      body: FutureBuilder<List<Achievement>>(
        future: futureAchievements,
        builder: (context, snapshot) {
          // --- 2. Obtenemos el tema DENTRO del Builder ---
          final theme = Theme.of(context);
          final colorScheme = theme.colorScheme;

          // Mientras carga los datos, muestra un spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hubo un error
          else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los logros: ${snapshot.error}'));
          }
          // Si los datos llegaron pero la lista está vacía
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aún no tienes logros. ¡Sigue participando!'));
          }
          // Si todo salió bien y hay datos
          else {
            final achievements = snapshot.data!;
            achievements.sort((a, b) {
              if (a.unlocked == b.unlocked) return 0;
              return a.unlocked ? -1 : 1;
            });
            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                // Diferencia visual para logros bloqueados
                final bool isUnlocked = achievement.unlocked;

                // --- 3. Usamos colores del tema ---
                // 'tertiary' suele ser un color de acento (como ámbar)
                final color = isUnlocked ? colorScheme.tertiary : colorScheme.onSurfaceVariant; // <-- Cambio

                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  // La tarjeta usará colorScheme.surface por defecto
                  child: Opacity(
                    opacity: isUnlocked ? 1.0 : 0.6, // Logros bloqueados se ven más tenues
                    child: ListTile(
                      // --- IMAGEN DESDE ASSETS ---
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundColor: color.withOpacity(0.2),
                        // La imagen se construye usando la URL del icono como nombre del archivo
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child:Image.asset(
                            'assets/images/logros/${achievement.id}.png',
                            // Manejo de error si la imagen no se encuentra
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.image_not_supported_outlined, color: colorScheme.error); // <-- Cambio
                            },
                          ),
                        ),
                      ),
                      title: Text(
                        achievement.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        // El color (onSurface) se hereda por defecto
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(achievement.description), // El color (onSurfaceVariant) se hereda por defecto
                          const SizedBox(height: 8),
                          // Barra de progreso si el logro no está desbloqueado
                          if (!isUnlocked)
                            LinearProgressIndicator(
                              value: (achievement.currentCount / achievement.requiredCount).clamp(0.0, 1.0),
                              backgroundColor: colorScheme.surfaceVariant, // <-- Cambio
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary), // <-- Cambio
                            ),
                          Text(
                            'Progreso: ${achievement.currentCount} / ${achievement.requiredCount}',
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant), // <-- Cambio
                          ),
                        ],
                      ),
                      trailing: Icon(
                        isUnlocked ? Icons.check_circle : Icons.lock,
                        color: color, // <-- Depende de la variable 'color'
                        size: 30,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}