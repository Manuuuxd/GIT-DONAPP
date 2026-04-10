import 'dart:collection';
import 'dart:convert';
import 'dart:developer' as console;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blood_game.dart';
import 'components.dart';

class ComponentState {
  final String type; // "DonorChip" | "NeedSlot" | "ReceptorZone"
  final String blood;
  final double x;
  final double y;
  final bool completed; // only relevant for NeedSlot

  ComponentState({
    required this.type,
    required this.blood,
    required this.x,
    required this.y,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'blood': blood,
    'x': x,
    'y': y,
    'completed': completed,
  };

  static ComponentState fromJson(Map<String, dynamic> json) => ComponentState(
    type: json['type'],
    blood: json['blood'],
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    completed: json['completed'] ?? false,
  );
}

extension BloodGameState on BloodGame {
  /// Save the current level and all dynamic components
  Future<void> saveLevelStateFull() async {
    final prefs = await SharedPreferences.getInstance();

    final List<ComponentState> components = [];

    // Save donors
    for (final donor in world.children.whereType<DonorChip>()) {
      components.add(ComponentState(
        type: 'DonorChip',
        blood: donor.blood,
        x: donor.position.x,
        y: donor.position.y,
      ));
    }

    // Save needs
    for (final need in world.children.whereType<NeedSlot>()) {
      components.add(ComponentState(
        type: 'NeedSlot',
        blood: need.blood,
        x: need.position.x,
        y: need.position.y,
        completed: need.completed,
      ));
    }

    // Save receptor zones (static, but in case dynamic)
    for (final rz in world.children.whereType<ReceptorZone>()) {
      components.add(ComponentState(
        type: 'ReceptorZone',
        blood: '',
        x: rz.area.left,
        y: rz.area.top,
      ));
    }

    final stateJson = jsonEncode({
      'currentLevel': currentLevel.value,
      'timeLeft': timeLeft.value.inSeconds,
      'correctLinks': correctLinks,
      'mistakes': mistakes,
      'resources': resources.value,
      'pendingNeeds': pendingNeeds.toList(),
      //'activeNeeds': activeNeeds.map((n) => n.toJson()).toList(),
      'availablePeople': availablePeople,
    });
    await prefs.setString('savedWorldState', stateJson);
    console.log('💾 Level state saved');
  }

  /// Load the saved level and restore all components
  Future<void> loadLevelStateFull() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('savedWorldState');
    if (jsonString == null) {
      console.log('⚠️ No saved world state found');
      return;
    }
    console.log('Loaded JSON: $jsonString');

    final Map<String, dynamic> data = jsonDecode(jsonString);

    // Clear existing world
    world.removeAll(world.children.toList());
    activeNeeds.clear();

    // Restore resources and progress
    resources.value = Map<String, int>.from(data['resources']);
    pendingNeeds = Queue<String>.from(data['pendingNeeds']);
    currentLevel.value = data['currentLevel'];
    timeLeft.value = Duration(seconds: data['timeLeft']);
    correctLinks = data['correctLinks'];
    mistakes = data['mistakes'];

    // Rebuild components
    final states = (data['components'] as List)
        .map((e) => ComponentState.fromJson(e))
        .toList();

    for (final s in states) {
      switch (s.type) {
        case 'DonorChip':
          world.add(DonorChip(blood: s.blood, position: Vector2(s.x, s.y)));
          break;
        case 'NeedSlot':
          late NeedSlot need; // declare first so onResolved can reference it
          need = NeedSlot(
            blood: s.blood,
            rect: Rect.fromLTWH(s.x, s.y, 120, 100),
            onResolved: () {
              activeNeeds.remove(need);
              if (pendingNeeds.isNotEmpty) {
                spawnNeed(pendingNeeds.removeFirst());
              }
            },
            restored: true,
          );
          if (s.completed) {
            need.complete(skipAnimation: true);
          } else {
            activeNeeds.add(need); // only add if not completed
          }
          world.add(need);
          break;

        case 'ReceptorZone':
          world.add(ReceptorZone(area: Rect.fromLTWH(s.x, s.y, 120, 100)));
          break;
      }
    }

    console.log('✅ Game world restored (${states.length} components)');
    levelRunning = true;
    restoreLevelTimer();
  }

  /// Optional: clear saved state
  Future<void> clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('savedWorldState');
    console.log('🗑️ Saved world state cleared');
  }

  void restoreLevelTimer() {
    levelTimer.removeFromParent();

    levelTimer = TimerComponent(
      period: 1,
      repeat: true,
      onTick: () {
        if (!levelRunning) return;
        if (timeLeft.value.inSeconds <= 0) {
          endLevel(timeExpired: true);
          return;
        }
        timeLeft.value = timeLeft.value - const Duration(seconds: 1);
      },
    );
    world.add(levelTimer);
  }
}
