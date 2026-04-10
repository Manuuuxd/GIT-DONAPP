// lib/screens/desafios/insignias_screen.dart

import 'package:flutter/material.dart';
import 'desafios_api_service.dart';
// Ya no necesitamos ApiConfig si las imágenes son locales, pero la mantengo si la usas para otras cosas.
// import 'package:donapp_android/CONFIG/api_config.dart';

class InsigniasScreen extends StatefulWidget {
  const InsigniasScreen({super.key});

  @override
  _InsigniasScreenState createState() => _InsigniasScreenState();
}

class _InsigniasScreenState extends State<InsigniasScreen> {
  final DesafiosApiService _apiService = DesafiosApiService();
  Future<List<dynamic>>? _insigniasFuture;

  // --- Mapeo de IDs de insignias a rutas de assets locales ---
  // ASUME que tus insignias de la API tendrán un 'id' o 'nombre' que puedas usar para mapear.
  // Aquí asumo que la primera insignia de tu lista es insignia1.png, la segunda insignia2.png, etc.
  // Si las insignias tienen IDs específicos que te permiten mapearlas de forma más robusta,
  // ajusta este mapa. Por ejemplo: {'id_constancia': 'assets/images/insignia1.png'}
  final Map<String, String> _insigniaAssetMap = {
    // Estas son rutas de ejemplo. Deberías adaptar esto a cómo identificas tus insignias desde la API.
    // Podrías usar el 'nombre' o un 'id' que viene en el objeto 'insignia' de la API.
    // Por ahora, estoy usando el índice para simular la asignación.
    // IDEALMENTE: asignarías por un identificador único real de la insignia, no por índice.
    // Por ejemplo:
    // 'Constancia': 'assets/images/insignia1.png',
    // 'Una Gota de Esperanza para un Desconocido': 'assets/images/insignia2.png',
    // 'De Receptor a Donante: Mi Círculo de Vida': 'assets/images/insignia3.png',
  };


  @override
  void initState() {
    super.initState();
    _insigniasFuture = _apiService.getMisInsignias();
  }

  // Helper para obtener la ruta del asset
  String _getAssetPathForInsignia(dynamic insignia, int index) {
    // Si tienes un mapeo más robusto por nombre o ID, úsalo aquí.
    // Por ejemplo:
    // String? path = _insigniaAssetMap[insignia['nombre']];
    // if (path != null) return path;

    // Si no, podemos usar el índice como fallback (menos robusto)
    return 'assets/images/insignia${index + 1}.png';
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Insignias'),
        backgroundColor: colorScheme.primary,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _insigniasFuture,
        builder: (context, snapshot) {
          final colorScheme = Theme.of(context).colorScheme;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aún no has ganado insignias. ¡Completa desafíos!'),
            );
          }

          final insignias = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: insignias.length,
            itemBuilder: (context, index) {
              final insignia = insignias[index];
              // --- CAMBIO AQUÍ: Obtenemos la ruta del asset local ---
              final assetPath = _getAssetPathForInsignia(insignia, index);

return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        assetPath,
                        height: 80,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.broken_image, size: 80, color: colorScheme.error),
                      ),
                      // --- ELIMINA O COMENTA ESTAS LÍNEAS ---
                      // const SizedBox(height: 12),
                      // Text(
                      //   insignia['nombre'],
                      //   textAlign: TextAlign.center,
                      //   style: const TextStyle(
                      //       fontSize: 16, fontWeight: FontWeight.bold),
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   insignia['descripcion'],
                      //   textAlign: TextAlign.center,
                      //   style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      //   maxLines: 2,
                      //   overflow: TextOverflow.ellipsis,
                      // ),
                      // -------------------------------------
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}