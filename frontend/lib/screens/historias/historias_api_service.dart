// lib/screens/historias/historias_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

class HistoriasApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('authToken');
    if (jwtToken == null) {
      throw Exception("Token no encontrado");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $jwtToken",
    };
  }

  /// Obtiene la siguiente historia recomendada para el usuario.
  Future<Map<String, dynamic>> getSiguienteHistoria() async {
    final url = Uri.parse(ApiConfig.endpoint('api/historias/siguiente/'));
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener la historia: ${response.body}');
    }
  }

  /// Registra una interacción (completada o no mostrar) con una historia.
  Future<void> interactuarConHistoria({
    required int historiaId,
    bool? completada,
    bool? noMostrar,
  }) async {
    final url = Uri.parse(ApiConfig.endpoint('api/historias/$historiaId/interactuar/'));
    final headers = await _getHeaders();
    final body = jsonEncode({
      if (completada != null) 'completada': completada,
      if (noMostrar != null) 'no_mostrar_de_nuevo': noMostrar,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Error al registrar la interacción: ${response.body}');
    }
  }
}