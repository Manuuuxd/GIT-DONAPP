import 'dart:developer' as console;
import 'dart:math';
import 'dart:collection';

import 'package:donapp_android/screens/Minigames/transfusion/loadgame.dart';
import 'package:http/http.dart' as http;

import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'compatibility.dart';
import 'leve.dart';
import 'components.dart';
import 'overlays/incorrect.dart';
import 'overlays/summary.dart';
import 'overlays/hint.dart';
import 'overlays/shared/hospital_request.dart';
import 'overlays/shared/positivemessage.dart';

class ComponentState {
  final String type; // "DonorChip" | "NeedSlot" | "ReceptorZone"
  final String blood;
  final double x;
  final double y;

  ComponentState({
    required this.type,
    required this.blood,
    required this.x,
    required this.y,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'blood': blood,
    'x': x,
    'y': y,
  };

  static ComponentState fromJson(Map<String, dynamic> json) {
    return ComponentState(
      type: json['type'],
      blood: json['blood'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
}


class GameProfile {
  int xp;
  int unlockedLevel;
  GameProfile({required this.xp, required this.unlockedLevel});
}

class BloodGame extends FlameGame
    with DragCallbacks, HasCollisionDetection, TapCallbacks, PanDetector {
  BloodGame({required this.onXpSync});


  @override
  bool debugMode = false;

  final ValueNotifier<bool> canSwipe = ValueNotifier(true);
  // Panels
  late Rect leftPanel;
  late Rect rightPanel;

  late final World world = World();
  late final CameraComponent cam;


  final Future<void> Function(GameProfile) onXpSync;
  late SharedPreferences prefs;

  GameProfile profile = GameProfile(xp: 0, unlockedLevel: 1);
  bool hasSavedGame = false;
  final ValueNotifier<int> xpNotifier = ValueNotifier(0);
  final ValueNotifier<int> unlockedLevelNotifier = ValueNotifier(1);
  double difficultyFactor = 1.0;
  void setProfile(GameProfile p) {
    profile = p;
    xpNotifier.value = p.xp;
    unlockedLevelNotifier.value = p.unlockedLevel;
  }

  void updateXp(int newXp, {int? newUnlockedLevel}) {
    profile.xp = newXp;
    profile.unlockedLevel = newUnlockedLevel ?? profile.unlockedLevel;
    xpNotifier.value = profile.xp;
    unlockedLevelNotifier.value = profile.unlockedLevel;

    prefs.setInt('xp', profile.xp);
    prefs.setInt('unlockedLevel', profile.unlockedLevel);
  }

  late TimerComponent levelTimer;
  final ValueNotifier<Duration> timeLeft = ValueNotifier(const Duration());

  late SpriteComponent _background;

  late Queue<String> pendingNeeds;
  final activeNeeds = <NeedSlot>[];
  String? _lastWrongDonor;
  String? _lastWrongRecipient;

  // Scoring / progress
  int correctLinks = 0;
  int mistakes = 0;
  int totalTargets = 0;
  int consecutiveFails = 0;
  double penaltyPct = 0.0;

  ValueNotifier<int> currentLevel = ValueNotifier(0);
  bool levelRunning = false;

  // Layout helpers
  late Rect leftColumn;
  late Rect rightColumn;
  ValueNotifier<String> positiveMessage = ValueNotifier<String>('');

  // Storage of bags
  ValueNotifier<Map<String, int>> resources = ValueNotifier({
    'A+': 3,
    'O-': 2,
    'B+': 1,
    'AB-': 1,
  });

  @override
  Future<void> onLoad() async {
    FlameAudio.bgm.initialize(); // Initialize BGM manager
    FlameAudio.bgm.play('TransfusionOST.mp3');

    await super.onLoad();
    await BloodSprites.loadAll();

    prefs = await SharedPreferences.getInstance();

    final savedXp = prefs.getInt('xp') ?? 0;
    final savedUnlockedLevel = prefs.getInt('unlockedLevel') ?? 1;
    final savedCurrentLevel = prefs.getInt('currentLevel') ?? 0;
    final savedState = prefs.getString('savedState');

    if (savedCurrentLevel > 0) {
      hasSavedGame = true;
      currentLevel.value = savedCurrentLevel;
    }

    profile = GameProfile(xp: savedXp, unlockedLevel: savedUnlockedLevel);
    xpNotifier.value = savedXp;
    unlockedLevelNotifier.value = savedUnlockedLevel;

    // Add the world and camera
    add(world);
    cam = CameraComponent(world: world);
    add(cam);

    // Wait until size is available
    await Future.delayed(Duration.zero);

    leftPanel = Rect.fromLTWH(0, 0, size.x, size.y);
    rightPanel = Rect.fromLTWH(size.x, 0, size.x, size.y);
    cam.setBounds(Rectangle.fromLTWH(0, 0, leftPanel.width, size.y));
    cam.moveTo(Vector2(size.x / 2, size.y / 2));

    console.log('Perfil cargado: XP=$savedXp, Nivel desbloqueado=$savedUnlockedLevel, Nivel actual=$savedCurrentLevel');
  }

  //@override
  //void onPanUpdate(DragUpdateInfo info) {
  //  if (info.handled) return;
  //  cam.moveBy(-info.delta.global);
  //}

//void moveToLeftPanel() {
    //  cam.moveTo(Vector2(size.x / 2, size.y / 2));
    //}
//
//void moveToRightPanel() {
    //  cam.moveTo(Vector2(size.x + size.x / 2, size.y / 2));
    //}
  void spawnNeed(String blood) {
    late NeedSlot slot; // declare first
    slot = NeedSlot(
      blood: blood,
      rect: Rect.fromLTWH(
        rightColumn.left,
        rightColumn.top + activeNeeds.length * 130,
        rightColumn.width,
        60,
      ),
      onResolved: () {
        activeNeeds.remove(slot);
        if (pendingNeeds.isNotEmpty) {
          spawnNeed(pendingNeeds.removeFirst());
        }
      },
    );

    activeNeeds.add(slot); // don’t forget to store it
    world.add(slot);       // if you want it visible in the game
  }

  /// Starts a level
  void startLevel(int level) async {
    currentLevel.value = level;
    canSwipe.value = true;
    prefs.setInt('currentLevel', level);
    prefs.setBool('levelRunning', true);
    levelRunning = true;
    correctLinks = 0;
    mistakes = 0;
    consecutiveFails = 0;
    penaltyPct = 0.0;

    world.removeAll(world.children.toList());

    // Columns
    leftColumn = Rect.fromLTWH(20, 120, size.x * 0.35, size.y - 150);
    rightColumn = Rect.fromLTWH(size.x * 0.6, 120, size.x * 0.3, size.y - 150);

    // Background
    final centroSprite = await loadSprite('centroTransfusion.jpg');
    _background = SpriteComponent()
      ..sprite = centroSprite
      ..size = size
      ..anchor = Anchor.topLeft
      ..position = Vector2.zero();
    world.add(_background);

    // Donors
    final data = LevelRepository.build(level);
    totalTargets = data.needs.length;

    world.add(ReceptorZone(area: Rect.fromLTWH(
      leftColumn.left,
      leftColumn.top,
      leftColumn.width + 20,
      data.needs.length * 100.0,
    )));

    for (var i = 0; i < data.donors.length; i++) {
      final d = data.donors[i];
      world.add(DonorChip(
        blood: d,
        position: Vector2(20, 100 + i * 100),
      ));
    }

    // Setup needs queue
    pendingNeeds = Queue.of(data.needs);

    // ==== Dificultad basada en el nivel ====
    final maxActiveNeeds = 3 + level; // Nivel 1 = 4, nivel 2 = 5, etc.
    final spawnPeriod = (5 - (level * 0.5)).clamp(1, 5); // Nivel alto = spawn más rápido
    final timeMinutes = (3 - (level - 1) * 0.3).clamp(1, 3); // Nivel alto = menos tiempo

    // Timer for spawning needs
    final spawnTimer = TimerComponent(
      period: spawnPeriod.toDouble(),
      repeat: true,
      onTick: () {
        if (activeNeeds.length < maxActiveNeeds && pendingNeeds.isNotEmpty) {
          spawnNeed(pendingNeeds.removeFirst());
        }
      },
    );
    world.add(spawnTimer);

    // Reset camera
    cam.moveTo(Vector2(size.x / 2, size.y / 2));

    // Timer principal
    timeLeft.value = Duration(minutes: timeMinutes.toInt());
    levelTimer = TimerComponent(
      period: 1,
      repeat: true,
      onTick: () {
        if (!levelRunning) return;
        final newLeft = timeLeft.value - const Duration(seconds: 1);
        timeLeft.value = newLeft;
        if (newLeft.inSeconds <= 0) {
          endLevel(timeExpired: true);
        }
      },
    );
    world.add(levelTimer);

    if (!FlameAudio.bgm.isPlaying) {
      FlameAudio.bgm.play('TransfusionOST.mp3', volume: 1.0);
    }

    // UI
    overlays.remove('MainMenu');
    overlays.add('HUD');
    overlays.add('PositiveMessage');
  }



  void onDropAttempt({required String donor, required String target, required Vector2 at}) {
    if (!levelRunning) return;
    final ok = BloodCompatibility.canDonate(donor, target);
    if (ok) {
      correctLinks++;
      consecutiveFails = 0;
      FlameAudio.play('ding.mp3');
      spawnPositiveParticles(at);
      showPositiveFeedback('¡Bien! $donor → $target');

      // Find the active NeedSlot with this target
      NeedSlot? slot;
      try {
        slot = activeNeeds.firstWhere((s) => s.blood == target);
      } catch (_) {
        slot = null;
      }
      slot?.complete(); // <- frees the space and triggers onResolved

    }else {
      mistakes++;
      consecutiveFails++;
      FlameAudio.play('error.mp3');

      _lastWrongDonor = donor;
      _lastWrongRecipient = target;

      incorrectMessage.value = '❌ $donor no coincide con $target';
      overlays.add('Incorrect');

      requestHint();
    }

    final finished = (correctLinks + mistakes) >= totalTargets; // all attempts done
    if (finished) {
      endLevel();
    }
  }
  String getHintForCurrentLevel() {
    if (_lastWrongDonor != null && _lastWrongRecipient != null) {
      // Explicación específica del último fallo
      return BloodCompatibility.explain(_lastWrongDonor!, _lastWrongRecipient!);
    }

    // Si no hay fallo registrado, pista genérica por nivel
    switch (currentLevel.value) {
      case 1:
        return 'Recuerda: A+ puede donar a A+ y AB+';
      case 2:
        return 'Observa qué tipos coinciden según el receptor';
      default:
        return 'Intenta emparejar donantes con receptores compatibles.';
    }
  }

  Future<void> fadeOutBgm({double duration = 1.0}) async {
    final player = FlameAudio.bgm.audioPlayer;
    if (player == null) return;

    final steps = 20;
    final stepDuration = duration / steps;
    for (int i = 0; i < steps; i++) {
      final vol = 1.0 - (i + 1) / steps;
      await player.setVolume(vol);
      await Future.delayed(Duration(milliseconds: (stepDuration * 1000).toInt()));
    }

    // Ensure it stops completely
    await player.stop();
    await player.setVolume(1.0); // reset for next play
  }
  Future<void> saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('xp', profile.xp);
    await prefs.setInt('unlockedLevel', profile.unlockedLevel);
  }
  void endLevel({bool timeExpired = false}) {
    if (!levelRunning) return;
    canSwipe.value = false;
    levelRunning = false;

    world.removeAll(world.children.toList());

    overlays.remove('HUD');

    levelTimer.removeFromParent();

    // Fade out BGM smoothly
    //fadeOutBgm(duration: 1.5);

    final rawPct = totalTargets == 0 ? 0.0 : (correctLinks / totalTargets);
    final finalPct = max(0.0, rawPct - penaltyPct);

    final unlockedNext = finalPct >= 0.80 && !timeExpired;
    final gainedXp = _xpForRun(finalPct, timeExpired: timeExpired);

    profile.xp += gainedXp;
    if (unlockedNext) {
      profile.unlockedLevel = max(profile.unlockedLevel, currentLevel.value + 1);
    }
    onXpSync(profile);
    saveProfile();
    prefs.setBool('levelRunning', false);
    prefs.remove('currentLevel');

    summaryData.value = LevelSummary(
      level: currentLevel.value,
      correct: correctLinks,
      mistakes: mistakes,
      total: totalTargets,
      percentage: finalPct,
      xpEarned: gainedXp,
      unlockedNext: unlockedNext,
      timeExpired: timeExpired,
      showKeyTable: mistakes >= 3 || timeExpired,
    );

    // Remove any lingering overlays
    overlays.remove('HUD');
    overlays.remove('MainMenu');

    // Decide whether to show Incorrect first
    if (finalPct < 0.8 || timeExpired) {
      incorrectMessage.value = '¡Revisa tus respuestas y vuelve a intentarlo!';
      overlays.add('Incorrect');

      // Wait for the user to dismiss Incorrect, then show Summary
      void listener() {
        if (!overlays.isActive('Incorrect')) {
          overlays.add('Summary');
          incorrectMessage.removeListener(listener);
        }
      }

      incorrectMessage.addListener(listener);
    }
    overlays.add('Summary');
  }

  int _xpForRun(double pct, {required bool timeExpired}) {
    int base = (pct * 100).round();
    if (timeExpired) base = (base * 0.6).round(); // penaliza si expiró
    return base.clamp(0, 100);
  }

  bool _hintUsed = false; // evita penalización repetida

  void requestHint() {
    if (!_hintUsed && consecutiveFails >= 2) {
      // Marca que ya se usó la pista
      _hintUsed = true;

      // Aplica penalización del 5%
      penaltyPct += 0.05;

      // Configura el texto de la pista (puede venir de tu lógica de nivel)
      hintText.value = getHintForCurrentLevel();

      // Muestra overlay de pista
      overlays.add('Hint');
    }
  }

  void showPositiveFeedback(String text) {
    positiveMessage.value = text;
    Future.delayed(const Duration(seconds: 2), () {
      positiveMessage.value = '';
    });
  }

  void spawnPositiveParticles(Vector2 at) {
    add(ParticleSystemComponent(
      position: at,
      particle: Particle.generate(
        count: 12,
        lifespan: 0.6,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 400),
          speed: Vector2.random()..scale(200),
          child: CircleParticle(radius: 2 + Random().nextDouble() * 3,
              paint: Paint()..color = Colors.red),
        ),
      ),
    ));
  }

  //MARKETING NEXT:
  // Selected type
  String selectedBloodType = 'O+';

// Probabilities
  double callSuccessProb = 0.7;
  double campaignSuccessProb = 0.9;

// Number of people for campaign
  int availablePeople = 5;

  /// Adds a donor in the left column, stacked like in the startLevel
  void addRawBag(String type) {
    final existing = world.children.whereType<DonorChip>().length;

    // Stack donors in the center-left table style
    final startX = leftColumn.left + 20;
    final startY = leftColumn.top + 0 + existing * 80;

    final chip = DonorChip(
      blood: type,
      position: Vector2(startX, startY),
    );

    world.add(chip);

    // Update inventory
    final current = Map<String, int>.from(resources.value);
    current[type] = (current[type] ?? 0) + 1;
    resources.value = current;
  }

  void performCall() {
    final r = Random().nextDouble();
    if (r <= callSuccessProb) {
      addRawBag(selectedBloodType);
      showPositiveFeedback('Conseguiste a un donante!');
    } else {
      showPositiveFeedback('No respondió el donante.');
    }
  }
  ValueNotifier<int> peopleNotifier = ValueNotifier(5);

  void performCampaign() {
    if (availablePeople <= 0) {
      showPositiveFeedback('¡No hay personas para realizar campañas!');
      return;
    }

    availablePeople--;
    peopleNotifier.value = availablePeople; // trigger UI update

    addRawBag(selectedBloodType);
    addRawBag(selectedBloodType);
    showPositiveFeedback('¡La campaña recolecto sangre!');
  }

  final hospitalRequests = ValueNotifier<List<HospitalRequest>>([]);

  void addHospitalRequest(String blood) {
    final r = HospitalRequest(bloodType: blood);
    hospitalRequests.value = [...hospitalRequests.value, r];

    // Auto-remove after duration
    Future.delayed(r.duration, () {
      final remaining = hospitalRequests.value.where((x) => x != r).toList();
      hospitalRequests.value = remaining;
    });
  }


  void fulfillRequest(HospitalRequest req) {
    final stock = resources.value[req.bloodType] ?? 0;
    if (stock >= req.unitsNeeded) {
      resources.value = {
        ...resources.value,
        req.bloodType: stock - req.unitsNeeded,
      };
      hospitalRequests.value = hospitalRequests.value..remove(req);
      showPositiveFeedback("Se lograron obtener: ${req.unitsNeeded}x ${req.bloodType}");
    } else {
      showPositiveFeedback("No hay sangre del tipo ${req.bloodType} para mantener las reservas");
    }
  }
  Future<void> saveLevelState(int level, Duration remaining, int correct, int mistakes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', level);
    await prefs.setInt('timeLeft', remaining.inSeconds);
    await prefs.setInt('correct', correct);
    await prefs.setInt('mistakes', mistakes);
  }

  Future<void> clearLevelState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentLevel');
  }

  Future<void> loadLevelState() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getInt('currentLevel');
    if (level != null) {
      final timeLeft = Duration(seconds: prefs.getInt('timeLeft') ?? 180);
      final correct = prefs.getInt('correct') ?? 0;
      final mistakes = prefs.getInt('mistakes') ?? 0;

      // Restaura el nivel al estado previo
      startLevel(level);
      this.correctLinks = correct;
      this.mistakes = mistakes;
      this.timeLeft.value = timeLeft;
    }
  }
}
extension BloodGameExit on BloodGame {
  void endLevelWithoutReward() async {
    if (!levelRunning) return;

    canSwipe.value = false;
    levelRunning = false;
    await saveLevelStateFull();

    // Clear all children and overlays
    world.removeAll(world.children.toList());
    overlays.remove('HUD');
    overlays.remove('MainMenu');

    // Stop level timer
    levelTimer.removeFromParent();

    // Stop any BGM (replace with your actual audio stop code)
    // FlameAudio.bgm.stop();

    // Do NOT award XP or unlock levels
    summaryData.value = LevelSummary(
      level: currentLevel.value,
      correct: correctLinks,
      mistakes: mistakes,
      total: totalTargets,
      percentage: 0.0, // zero because we don’t award XP
      xpEarned: 0,
      unlockedNext: false,
      timeExpired: true,
      showKeyTable: false,
    );

    overlays.add('Summary'); // show summary overlay if desired
  }
}