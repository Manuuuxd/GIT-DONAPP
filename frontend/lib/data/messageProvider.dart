import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class MessageProvider {
  List<String> mensajesEmpaticos = [];

  Future<void> loadMessages() async {
    final jsonString = await rootBundle.loadString('assets/Formulario/mensajesEmpaticos.json');
    final data = json.decode(jsonString) as Map<String, dynamic>;
    mensajesEmpaticos = List<String>.from(data['mensajes_empaticos']);
  }

  String getRandomEmpatico() {
    if (mensajesEmpaticos.isEmpty) {
      return "Gracias por tu interés y compromiso";
    }
    final random = Random();
    return mensajesEmpaticos[random.nextInt(mensajesEmpaticos.length)];
  }
}