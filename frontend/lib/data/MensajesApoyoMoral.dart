import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class MessageProvider {
  Map<String, List<String>> _messagesByScore = {};

  Future<void> loadMessages() async {
    final jsonString = await rootBundle.loadString('assets/Trivia/frases_correcta.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    _messagesByScore = data.map((key, value) {
      final list = List<String>.from(value);
      return MapEntry(key, list);
    });
  }

  String getRandomMessageForScore(int score) {
    final key = score.toString();
    final messages = _messagesByScore[key];

    if (messages == null || messages.isEmpty) {
      return "¡Buen trabajo! Sigue adelante.";
    }

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}
