// lib/screens/historias/historias_screen.dart


// lib/screens/historias/historias_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart'; // <-- Paquete nuevo
import 'package:path_provider/path_provider.dart'; // <-- Paquete nuevo
import 'historias_api_service.dart';
import 'package:donapp_android/colours/app_colors.dart';

class HistoriasScreen extends StatefulWidget {
  const HistoriasScreen({super.key});

  @override
  State<HistoriasScreen> createState() => _HistoriasScreenState();
}

class _HistoriasScreenState extends State<HistoriasScreen> {
  final HistoriasApiService _apiService = HistoriasApiService();
  Future<Map<String, dynamic>>? _historiaFuture;
  Map<String, dynamic>? _historiaActual;

  // --- (CA04) Controlador para la captura de pantalla ---
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _cargarSiguienteHistoria();
  }

  void _cargarSiguienteHistoria() {
    setState(() {
      _historiaActual = null;
      _historiaFuture = _apiService.getSiguienteHistoria();
    });
  }

  // --- (CA04) Función para compartir como imagen (MODIFICADA) ---
  void _compartirHistoria() async {
    if (_historiaActual != null) {
      // Capturamos el widget 'HistoriaParaCompartir' y lo convertimos a imagen
      final Uint8List? imageBytes = await _screenshotController.captureFromWidget(
        HistoriaParaCompartir(
          titulo: _historiaActual!['titulo'],
          contenido: _historiaActual!['contenido'],
        ),
        // Aumentamos la calidad de la imagen
        pixelRatio: 2.0,
      );

      if (imageBytes != null) {
        // Guardamos la imagen en un archivo temporal
        final directory = await getTemporaryDirectory();
        final imagePath = await File('${directory.path}/historia.png').create();
        await imagePath.writeAsBytes(imageBytes);

        // Compartimos el archivo de imagen
        await Share.shareXFiles([XFile(imagePath.path)], text: "¡Mira esta historia inspiradora de DonApp!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. Obtenemos el tema y los colores
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historias que Inspiran'),
        // 💡 2. Eliminamos el color fijo para que el AppBar use el tema
        // backgroundColor: AppColors.customBlue, 
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _historiaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 💡 3. Usamos un color de tema (secundario)
                    Icon(Icons.bookmark_added, size: 60, color: colors.onSurfaceVariant.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      '¡Felicidades! Has leído todas las historias disponibles.',
                      textAlign: TextAlign.center,
                      // 💡 4. Usamos un color de texto de tema
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No hay historias disponibles.'));
          }

          _historiaActual = snapshot.data!;
          final historia = _historiaActual!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  historia['titulo'],
                  // 💡 5. Usamos un estilo y color de texto de tema
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const Divider(height: 32),
                Text(
                  historia['contenido'],
                  // 💡 6. ¡Este ya era bueno! Sin color fijo, usará el tema.
                  style: const TextStyle(fontSize: 17, height: 1.5),
                ),
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Lectura Completada'),
                  style: ElevatedButton.styleFrom(
                    // Este color verde es 'semántico' (de éxito), 
                    // así que está bien mantenerlo.
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white, // Asegura texto blanco
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    _apiService.interactuarConHistoria(
                      historiaId: historia['id'],
                      completada: true,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('¡Logro obtenido! Gracias por leer.')),
                    );
                    _cargarSiguienteHistoria();
                  },
                ),
                const SizedBox(height: 12),
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir como Imagen'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  // 💡 7. Este botón usará 'colors.primary' automáticamente
                  onPressed: _compartirHistoria,
                ),
                
                Center(
                  child: TextButton(
                    // 💡 8. Este botón usará 'colors.primary' automáticamente
                    child: const Text('No mostrar esta historia de nuevo'),
                    onPressed: () {
                      _apiService.interactuarConHistoria(
                        historiaId: historia['id'],
                        noMostrar: true,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No te volveremos a sugerir esta historia.')),
                      );
                      _cargarSiguienteHistoria();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// --- (CA04) WIDGET ESPECIAL PARA LA IMAGEN A COMPARTIR ---
class HistoriaParaCompartir extends StatelessWidget {
  final String titulo;
  final String contenido;

  const HistoriaParaCompartir({
    super.key,
    required this.titulo,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    // 💡 NOTA: No se aplica modo oscuro aquí.
    // Este widget se renderiza 'fuera de pantalla' para crear una
    // imagen estática (como una postal). 
    // Debe tener un diseño fijo y de marca.
    return Material(
      child: Container(
        width: 400, // Ancho fijo para la imagen
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          // Fondo degradado
          gradient: LinearGradient(
            colors: [Color(0xFFE6F2FF), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Para que el alto se ajuste al contenido
          children: [
            // Logo o icono de la app
            Row(
              children: [
                // Asume que tienes un logo en 'assets/images/icon.png'
                // Image.asset('assets/images/icon.png', height: 30),
                Icon(Icons.bloodtype, size: 30, color: AppColors.customBlue), // Placeholder
                const SizedBox(width: 8),
                const Text(
                  'DonApp - Historia que Inspira',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.customBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Título de la historia
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const Divider(height: 24),
            // Contenido de la historia
            Text(
              // Acortamos el texto para que quepa bien en la imagen
              '${contenido.substring(0, (contenido.length > 280) ? 280 : contenido.length)}...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            // Este Spacer() flexible podría dar problemas, lo quitamos
            // const Spacer(), 
            const SizedBox(height: 40), // Espacio fijo es más seguro
            const Text(
              'Descarga DonApp y salva vidas.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}