import 'dart:math';

class LevelData {
  final List<String> donors; // izquierda
  final List<String> needs; // derecha (receptores)
  final int durationInSeconds; // 👈 Añadido
  final double spawnPeriodSeconds; // 👈 Añadido

  LevelData({
    required this.donors,
    required this.needs,
    required this.durationInSeconds,
    required this.spawnPeriodSeconds,
  });
}

class LevelRepository {
  static LevelData build(int level) {
    final types = ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'];
    // El 'seed' (level) asegura que el nivel sea siempre igual
    final rng = Random(level);

    // Donors: 6 tipos aleatorios, pero consistentes para ese nivel
    final donors = List<String>.from(types)..shuffle(rng);

    // Needs: Escala con el nivel
    final needs = <String>[];
    final needsCount = 6 + (level * 2); // Más receptores en niveles altos
    for (int i = 0; i < needsCount; i++) {
      needs.add(types[rng.nextInt(types.length)]);
    }

    // 💡 Lógica de dificultad progresiva
    int duration;
    double spawnPeriod;

    switch (level) {
      case 1: // Nivel Fácil
        duration = 240; // 4 minutos
        spawnPeriod = 8.0; // Lento
        break;
      case 2:
        duration = 210; // 3.5 minutos
        spawnPeriod = 7.0;
        break;
      case 3:
        duration = 180; // 3 minutos (Estándar)
        spawnPeriod = 6.0;
        break;
      case 4:
        duration = 150; // 2.5 minutos
        spawnPeriod = 5.0;
        break;
      default: // Nivel 5+ (Difícil)
        duration = 120; // 2 minutos
        spawnPeriod = 4.5; // Rápido
        break;
    }

    return LevelData(
      donors: donors.take(6).toList(),
      needs: needs,
      durationInSeconds: duration,
      spawnPeriodSeconds: spawnPeriod,
    );
  }

  static String suggestHint() {
    return 'Pista: Receptor AB+ acepta de todos. Receptor O− solo de O−.';
  }
}