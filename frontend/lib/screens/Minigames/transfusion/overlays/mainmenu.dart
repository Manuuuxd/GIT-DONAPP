import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../blood_game.dart';
import '../components.dart';


class MainMenuOverlay extends StatefulWidget {
  final BloodGame game;
  const MainMenuOverlay(this.game, {super.key});

  @override
  State<MainMenuOverlay> createState() => _MainMenuOverlayState();
}

class _MainMenuOverlayState extends State<MainMenuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return FadeTransition(
      opacity: _fadeIn,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFFE53935)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.0)
                .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bloodtype, size: 72, color: Colors.redAccent),
                    const SizedBox(height: 12),
                    const Text(
                      'Juego de Compatibilidad Sanguínea',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Perfil
                    ValueListenableBuilder<int>(
                      valueListenable: game.xpNotifier,
                      builder: (_, xp, __) => ValueListenableBuilder<int>(
                        valueListenable: game.unlockedLevelNotifier,
                        builder: (_, unlocked, __) => Text(
                          'Perfil — XP: $xp\nNiveles desbloqueados: $unlocked',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Botones de nivel
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          AnimatedOpacity(
                            opacity: i <= game.profile.unlockedLevel ? 1 : 0.4,
                            duration: const Duration(milliseconds: 300),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: i <= game.profile.unlockedLevel
                                    ? Colors.redAccent
                                    : Colors.grey.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: i <= game.profile.unlockedLevel
                                  ? () => game.startLevel(i)
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: Text('Nivel $i',
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder(
                      future: SharedPreferences.getInstance(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final prefs = snapshot.data!;
                        final hasSavedLevel = prefs.containsKey('savedWorldState');
                        return hasSavedLevel
                            ? ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Continuar partida'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            await BloodSprites.loadAll();
                            await game.loadLevelState();
                            game.overlays.remove('MainMenu');
                          },
                        )
                            : const SizedBox();
                      },
                    ),
                    const SizedBox(height: 20),

                    OutlinedButton.icon(
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Cómo jugar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueAccent,
                        side: const BorderSide(color: Colors.blueAccent),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onPressed: () => game.overlays.add('Hint'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
