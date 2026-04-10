import 'package:flutter/material.dart';
import 'desafios_api_service.dart';
import 'package:donapp_android/colours/app_colors.dart';
import 'insignias_screen.dart';

// --- NUEVA FUNCIÓN DE AYUDA ---
/// Intenta completar un desafío si el tipo coincide con uno de los desafíos activos.
///
/// [context]: El BuildContext actual para mostrar Snackbars.
/// [tipoDesafio]: El tipo de desafío que se intenta completar (ej: "abrir_app").
Future<void> intentarCompletarDesafio(BuildContext context, String tipoDesafio) async {
  // ... (El resto de esta función ya es correcta y no necesita cambios) ...
  final apiService = DesafiosApiService();
  try {
    // 1. Obtener los desafíos semanales activos
    final data = await apiService.getSiguienteDesafio();
    final List<dynamic> desafiosActivos = data['desafios'] ?? [];

    // 2. Buscar si existe un desafío del tipo especificado
    final desafioParaCompletar = desafiosActivos.firstWhere(
      (d) => d['tipo'] == tipoDesafio,
      orElse: () => null, // Devuelve null si no se encuentra
    );

    // 3. Si se encontró un desafío de ese tipo, intentar completarlo
    if (desafioParaCompletar != null) {
      // Antes de completar, verificamos si ya está en el historial
      final historial = await apiService.getMisDesafios();
      bool yaCompletado = historial.any((h) =>
          h['desafio'] != null &&
          h['desafio']['id'] == desafioParaCompletar['id'] &&
          h['estado'] == 'completado');

      if (!yaCompletado) {
        await apiService.crearDesafioUsuario(
          desafioId: desafioParaCompletar['id'],
          estado: 'completado',
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Has completado el desafío: ${desafioParaCompletar['nombre']}! 🎉')),
          );
        }
        print('Desafío "$tipoDesafio" completado exitosamente.');
      } else {
        print('El desafío de tipo "$tipoDesafio" ya fue completado esta semana.');
      }
    } else {
      print('No hay desafío activo del tipo "$tipoDesafio".');
    }
  } catch (e) {
    print('Error al intentar completar el desafío: $e');
    // La función falla silenciosamente para no interrumpir al usuario.
  }
}


// Extensión para capitalizar la primera letra del estado
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  final DesafiosApiService _apiService = DesafiosApiService();
  Future<Map<String, dynamic>>? _desafiosActualesFuture;
  Future<List<dynamic>>? _historialDesafiosFuture;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    // --- CAMBIO AQUÍ ---
    // Llamamos a la función para intentar completar el desafío al entrar a esta pantalla.
    // Usamos addPostFrameCallback para asegurar que el `context` esté disponible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        intentarCompletarDesafio(context, 'abrir_app');
      }
    });
  }

  void _cargarDatos() {
    setState(() {
      _desafiosActualesFuture = _apiService.getSiguienteDesafio();
      _historialDesafiosFuture = _apiService.getMisDesafios();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- 1. Obtenemos el tema ---
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // <-- Cambio
        appBar: AppBar(
          title: const Text('Mis Desafíos'),
          backgroundColor: colorScheme.primary, // <-- Cambio
          actions: [
            IconButton(
              // Usamos un color de acento del tema
              icon: Icon(Icons.emoji_events_rounded, color: colorScheme.tertiary), // <-- Cambio
              tooltip: 'Mis Insignias',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InsigniasScreen()),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Desafíos Activos', icon: Icon(Icons.star_rounded)),
              Tab(text: 'Historial', icon: Icon(Icons.history_rounded)),
            ],
            // Los colores de la TabBar se heredan de la AppBar (onPrimary)
          ),
        ),
        body: TabBarView(
          children: [
            _buildDesafiosActuales(),
            _buildHistorialDesafios(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET MODIFICADO ---
  Widget _buildDesafiosActuales() {
    // No necesitamos el tema aquí, se lo pasamos al builder
    return FutureBuilder<Map<String, dynamic>>(
      future: _desafiosActualesFuture,
      builder: (context, snapshot) {
        // --- 2. Obtenemos el tema DENTRO del builder ---
        final colorScheme = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error.toString()}'));
        }

        // Extraemos la lista de desafíos y la frase
        final List<dynamic> desafios = snapshot.data?['desafios'] ?? [];
        final frase = snapshot.data?['frase_motivacional'];

        if (desafios.isEmpty) {
          return const Center(child: Text('¡Genial! No hay desafíos pendientes esta semana.'));
        }

        // Usamos un ListView para mostrar todos los desafíos y la frase
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          // +1 para el espacio de la frase motivacional si existe
          itemCount: desafios.length + (frase != null ? 1 : 0),
          itemBuilder: (context, index) {
            // Si hay una frase y es el último elemento, la mostramos
            if (frase != null && index == desafios.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer, // <-- Cambio
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outline), // <-- Cambio
                  ),
                  child: Text(
                    frase,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: colorScheme.onPrimaryContainer), // <-- Cambio
                  ),
                ),
              );
            }
            
            // Obtenemos el desafío actual de la lista
            final desafio = desafios[index];

            return Card(
              elevation: 4,
              // Usamos colores de la tarjeta del tema
              color: colorScheme.surface, // <-- Cambio
              shadowColor: Theme.of(context).shadowColor, // <-- Cambio
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      desafio['nombre'],
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary), // <-- Cambio
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desafio['descripcion'], 
                      // El color se hereda (onSurface)
                      style: const TextStyle(fontSize: 16) 
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('¡Lo completé!'),
                      // Usamos el color semántico de AppColors que ya tenías
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success), // <-- Cambio (Mantenemos color semántico)
                      onPressed: () async {
                        try {
                          await _apiService.crearDesafioUsuario(
                            desafioId: desafio['id'],
                            estado: 'completado',
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('¡Felicidades! Desafío completado 🥳')),
                          );
                          _cargarDatos();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${e.toString()}')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistorialDesafios() {
    return FutureBuilder<List<dynamic>>(
      future: _historialDesafiosFuture,
      builder: (context, snapshot) {
        // --- 3. Obtenemos el tema DENTRO del builder ---
        final colorScheme = Theme.of(context).colorScheme;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error.toString()}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tu historial de desafíos está vacío.'));
        }

        final desafios = snapshot.data!;

        return ListView.builder(
          itemCount: desafios.length,
          itemBuilder: (context, index) {
            final d = desafios[index];
            final estado = (d['estado'] ?? 'pendiente').toString();
            final nombreDesafio = (d['desafio'] is Map ? d['desafio']['nombre'] : 'Desafío') ?? 'Desafío';

            // --- 4. Asignamos colores del tema ---
            Color estadoColor;
            if (estado == 'completado') {
              estadoColor = AppColors.success; // Color semántico
            } else if (estado == 'fallido') {
              estadoColor = colorScheme.error; // Color de error del tema
            } else {
              estadoColor = colorScheme.onSurfaceVariant; // Color neutro
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: ListTile(
                leading: Icon(
                  estado == 'completado' ? Icons.check_circle : (estado == 'fallido' ? Icons.cancel : Icons.hourglass_empty),
                  color: estadoColor, // <-- Cambio
                ),
                title: Text(nombreDesafio),
                subtitle: Text("Estado: ${estado.capitalize()}"),
              ),
            );
          },
        );
      },
    );
  }
}
