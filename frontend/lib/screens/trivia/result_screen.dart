// lib/screens/trivia/result_screen.dart

import 'package:flutter/material.dart';
import 'pantallaSeleccion.dart'; // Para reiniciar en la selección de nivel

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final String nivel; 
  final String avatarFinal; // <-- CA04: Avatar de la última respuesta

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.nivel,
    required this.avatarFinal, // <-- Recibimos el avatar
  });
  
  String getNombreNivel(int nivel) {
    if (nivel <= 3) return "Inicial";
    if (nivel <= 6) return "Avanzado";
    return "Experto";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final int xpGanado = score * 10; // Cálculo de ejemplo para XP
    final bool passed = (score / total) >= 0.5;
    
    // CA04: Determina el avatar final
    final String resultAvatar = passed ? 'assets/images/heroe.png' : 'assets/images/lloron.png';
    final Color colorPrincipal = passed ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // CA04: Mascota (MÁS GRANDE)
              Image.asset(
                resultAvatar, // <-- Muestra el avatar de resultado
                height: 140, // <-- Tamaño aumentado
              ),
              const SizedBox(height: 24),
              
              Text(
                passed ? '¡Trivia Completada!' : '¡Sigue Intentando!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Completaste el Nivel $nivel',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Tarjeta de resultados
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ResultStat(
                      label: 'Correctas',
                      value: '$score/$total',
                      color: Colors.green,
                    ),
                    _ResultStat(
                      label: 'XP Ganado',
                      value: '+$xpGanado',
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Botones de acción
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const NivelIntroScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Jugar de nuevo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Vuelve a la pantalla principal (home)
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: theme.colorScheme.outline),
                ),
                child: const Text('Volver al inicio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar una estadística individual en la tarjeta
class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  
  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}