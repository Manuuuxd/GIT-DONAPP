import 'package:flutter/material.dart';
import '../blood_game.dart';

class LevelSummary {
  final int level;
  final int correct;
  final int mistakes;
  final int total;
  final double percentage;
  final int xpEarned;
  final bool unlockedNext;
  final bool timeExpired;
  final bool showKeyTable;
  LevelSummary({
    required this.level,
    required this.correct,
    required this.mistakes,
    required this.total,
    required this.percentage,
    required this.xpEarned,
    required this.unlockedNext,
    required this.timeExpired,
    required this.showKeyTable,
  });
}

final summaryData = ValueNotifier<LevelSummary?>(null);

class SummaryOverlay extends StatelessWidget {
  final BloodGame game;
  const SummaryOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el tema y los colores
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final s = summaryData.value!;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        // 2. Mismo gradiente adaptativo que el MainMenu
        gradient: LinearGradient(
          colors: [
            colors.primary.withOpacity(0.8),
            colors.background
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: SingleChildScrollView( // Añadido para evitar overflow en pantallas pequeñas
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: const EdgeInsets.all(32),
            // 3. Color de tarjeta adaptativo
            color: colors.surface.withOpacity(0.95),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 4. Icono con color primario
                  Icon(Icons.bloodtype, size: 64, color: colors.primary),
                  const SizedBox(height: 12),
                  // 5. Estilos de texto adaptativos
                  Text(
                    'Nivel ${s.level} — Resultado',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface, 
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.timeExpired
                        ? '⏰ Nivel terminado por tiempo'
                        : '✅ Nivel completado',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Aciertos: ${s.correct} / ${s.total}', style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface)),
                  Text('Errores: ${s.mistakes}', style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface)),
                  Text('Puntaje: ${(s.percentage * 100).toStringAsFixed(0)} %', style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface)),
                  Text('XP obtenida: ${s.xpEarned}', style: theme.textTheme.bodyLarge?.copyWith(color: colors.onSurface, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  if (s.unlockedNext)
                    Text(
                      '🎉 ¡Desbloqueaste el siguiente nivel!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.primary, // Color especial para destacar
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  
                  if (s.showKeyTable)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FilledButton(
                        onPressed: () {
                          game.overlays.add('KeyTable');
                        },
                        child: const Text('Ver compatibilidades clave'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  // Los botones se adaptan solos, pero los envolvemos
                  // para que se ajusten bien en pantallas pequeñas
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      FilledButton(
                        onPressed: () {
                          game.startLevel(game.currentLevel.value); // rejugar
                          game.overlays.remove('Summary');
                        },
                        child: const Text('Reintentar'),
                      ),
                      FilledButton.tonal(
                        onPressed: () {
                          game.overlays.remove('Summary');
                          game.overlays.add('MainMenu');
                        },
                        child: const Text('Menú principal'),
                      ),
                      if (s.unlockedNext)
                        FilledButton(
                          onPressed: () {
                            game.overlays.remove('Summary');
                            game.startLevel(game.currentLevel.value + 1);
                          },
                          child: const Text('Siguiente nivel'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    }
  }