import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class FailMessageProvider {
  Map<String, List<String>> _failMessagesByCount = {};

  Future<void> loadFailMessages() async {
    final jsonString = await rootBundle.loadString('assets/Trivia/frases_fallos.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;

    _failMessagesByCount = data.map((key, value) {
      final list = List<String>.from(value);
      return MapEntry(key, list);
    });
  }

  String getRandomMessageForFails(int fails) {
    final key = fails.toString();
    final messages = _failMessagesByCount[key];

    if (messages == null || messages.isEmpty) {
      return "❌ No es correcto, pero sigue adelante. Aprenderás algo nuevo.";
    }

    final random = Random();
    return messages[random.nextInt(messages.length)];
  }
}
