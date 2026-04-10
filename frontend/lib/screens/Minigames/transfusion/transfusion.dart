// ============================
// lib/main.dart
// ============================
import 'dart:convert';
import 'dart:developer' as console;

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../CONFIG/api_config.dart';
import 'blood_game.dart';
import 'overlays/hint.dart';
import 'overlays/marketing.dart';
import 'overlays/HDU.dart';
import 'overlays/hospital.dart';
import 'overlays/mainmenu.dart';
import 'overlays/summary.dart';
import 'overlays/incorrect.dart';
import 'overlays/keytable.dart';
import 'overlays/shared/positivemessage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setPortrait();

  runApp(const BloodCompatibilityApp());
}

class BloodCompatibilityApp extends StatefulWidget {
  const BloodCompatibilityApp({super.key});

  @override
  State<BloodCompatibilityApp> createState() => _BloodCompatibilityAppState();
}

class _BloodCompatibilityAppState extends State<BloodCompatibilityApp> {


  late final BloodGame _game;
  int _xp = 0;
  int _unlockedLevel = 1;

  @override
  void initState() {
    super.initState();

    _loadProfile();
    _game = BloodGame(onXpSync: _syncXp);
    // Lock to portrait while this widget is active
    Flame.device.setPortrait();
  }
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final url = Uri.parse(ApiConfig.endpoint("api/experiencia/"));
    final token = prefs.getString('authToken');
    int xp;
    int unlockedLevel;

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        console.log(data);
        xp = data['xp'];
        unlockedLevel = data['unlockedLevel'];

        // update local cache
        await prefs.setInt('xp', xp);
        await prefs.setInt('unlockedLevel', unlockedLevel);
      } else {
        // fallback to local
        xp = prefs.getInt('xp') ?? 0;
        unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
      }
    } catch (e) {
      xp = prefs.getInt('xp') ?? 0;
      unlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    }

    setState(() {
      _game.setProfile(GameProfile(xp: xp, unlockedLevel: unlockedLevel));
    });
  }

  Future<void> _syncXp(GameProfile p) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('xp', p.xp);
    await prefs.setInt('unlockedLevel', p.unlockedLevel);

    setState(() {
      _game.setProfile(p); // ✅ use the passed profile
    });

    final url = Uri.parse(ApiConfig.endpoint("api/users/experiencia/"));
    final token = prefs.getString('authToken');

    try {
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'xp': p.xp,
          'unlockedLevel': p.unlockedLevel,
        }),
      );
    } catch (e) {
      print("Failed to sync XP: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.redAccent),
      home: Scaffold(
        body: PanelManager(game: _game), // 👈 only use PanelManager
      ),
    );
  }
}
class PanelManager extends StatefulWidget {
  final BloodGame game;
  const PanelManager({super.key, required this.game});

  @override
  State<PanelManager> createState() => _PanelManagerState();
}
class _PanelManagerState extends State<PanelManager> {
  final PageController _controller = PageController(initialPage: 1);

  bool _initialMenuShown = false; // remember we already added it

  @override
  void initState() {
    super.initState();
    // Add MainMenu overlay once the first frame is rendered and GameWidget is mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialMenuShown) {
        try {
          widget.game.overlays.add('MainMenu');
          _initialMenuShown = true;
        } catch (_) {
          // If overlays manager isn't ready yet, ignore — we'll try again on next frame
          // (rare). Or you could schedule another microtask if you prefer.
        }
      }
    });
  }

  bool get _isLevelActive => widget.game.currentLevel.value > 0; // true if a level is selected

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.currentLevel,
      builder: (_, level, __) {
        return ValueListenableBuilder<bool>(
          valueListenable: widget.game.canSwipe,
          builder: (_, canSwipe, __) {
            return PageView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: (level == 0 || !canSwipe)
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: [
                MarketingOverlay(widget.game),
                SizedBox.expand(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GameWidget<BloodGame>(
                        game: widget.game,
                        overlayBuilderMap: {
                          'Incorrect': (context, game) => IncorrectOverlay(game),
                          'Hint': (context, game) => HintOverlay(game),
                          'KeyTable': (context, game) => KeyTableOverlay(game),
                          'HUD': (context, game) => HUDOverlay(game),
                          'MainMenu': (context, game) => Positioned.fill(
                            child: MainMenuOverlay(game),
                          ),
                          'Summary': (context, game) => Positioned.fill(
                            child: Material(
                              color: Colors.black.withOpacity(0.8),
                              elevation: 9999,
                              child: SummaryOverlay(game),
                            ),
                          ),
                          'PositiveMessage': (context, game) =>
                              PositiveMessageOverlay(game),
                        },
                        initialActiveOverlays: const [],
                      ),
                    ],
                  ),
                ),
                HospitalOverlay(widget.game),
              ],
            );
          },
        );
      },
    );
  }
}

/*
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.15.0
  flame_audio: ^2.10.2
  shared_preferences: ^2.3.2

flutter:
  assets:
    - assets/audio/ding.mp3
    - assets/audio/buzz.mp3
    # opcional: - assets/audio/bgm.mp3
*/

// ============================
// Notas de implementación
// ============================
/*
✔ Criterios cubiertos:
- Incorrecto con explicación textual: overlay 'Incorrect' con BloodCompatibility.explain().
- ≥80% aciertos desbloquea siguiente nivel: en endLevel().
- ≥3 errores o expiración → resumen educativo y tabla clave: Summary + KeyTable.
- Asignación de XP al completar nivel: _xpForRun() y sync via SharedPreferences.
- Temporizador visible y expiración a 3 min: HUD y TimerComponent.
- Feedback positivo personalizado: positiveMessage (se usa en onDropAttempt con partículas y sonido).
- Registro "nivel terminado por tiempo": flag timeExpired en Summary.
- Pista tras dos fallos seguidos y penalización −5%: requestHint().

Pendiente para producción (stubs listos):
- Mostrar positiveMessage en HUD (p.ej. SnacckBar o Chip reactivo).
- Sistema de niveles con configuraciones más ricas (e.g., pesos, distractores, layouts, sprites/arte).
- Evitar múltiples intentos sobre el mismo NeedSlot tras acierto (marcar como completado/lock).
- Audio: agregar archivos en assets.
- Tests unitarios de BloodCompatibility.canDonate y explain.
*/
