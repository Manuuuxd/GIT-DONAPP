import 'package:donapp_android/screens/home_screen.dart'; // Aunque ya no se usa, lo dejamos
import 'package:flutter/material.dart';
import '../blood_game.dart';


class HUDOverlay extends StatelessWidget {
  final BloodGame game;
  const HUDOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el tema y los colores
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 10 + MediaQuery.of(context).padding.top, // 👈 suma el notch/status bar
          bottom: 10,
        ),
        decoration: BoxDecoration(
          // 2. Usamos el color primario del tema
          color: colors.primary.withOpacity(0.9), 
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timer grande
                ValueListenableBuilder<Duration>(
                  valueListenable: game.timeLeft,
                  builder: (_, t, __) => Text(
                    '${t.inMinutes}:${(t.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      // 3. Usamos 'onPrimary' (color para texto sobre 'primary')
                      color: colors.onPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Botón menú
                PopupMenuButton<String>(
                  // 4. Icono también usa 'onPrimary'
                  icon: Icon(Icons.menu, color: colors.onPrimary, size: 28),
                  // 5. El fondo del menú desplegable usa 'surface'
                  color: colors.surface, 
                  onSelected: (value) {
                    if (value == 'salir') {
                      _showExitDialog(context, game);
                    } else if (value == 'sonido') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Opción de sonido aún no implementada'),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sonido',
                      child: Text('Opciones de sonido'),
                    ),
                    const PopupMenuItem(
                      value: 'salir',
                      child: Text('Salir al menú principal'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
void _showExitDialog(BuildContext context, BloodGame game) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Salir al menú principal'),
      content: const Text(
          '¿Seguro que quieres salir? Se mostrará el resumen del nivel sin recompensa.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            // 1. Llama a tus funciones del juego
            game.fadeOutBgm(duration: 1.0);
            game.endLevelWithoutReward(); // 👈 Esto mostrará el SummaryOverlay

            // 2. Cierra el diálogo
            Navigator.of(context, rootNavigator: true).pop();

            // 3. ❌ NAVEGACIÓN ROTA ELIMINADA
            // (La línea de pushAndRemoveUntil se eliminó)
          },
          child: const Text('Salir'),
        ),

      ],
    ),
  );
}