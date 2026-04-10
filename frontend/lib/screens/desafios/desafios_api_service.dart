// lib/screens/desafios/desafios_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

class DesafiosApiService {
  // Método privado para obtener las cabeceras con el token
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = prefs.getString('authToken');
    if (jwtToken == null) {
      throw Exception("Token de autenticación no encontrado");
    }
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $jwtToken",
    };
  }

  // GET /api/desafios/siguiente/
  Future<Map<String, dynamic>> getSiguienteDesafio() async {
    // Esta ruta parece estar bien según el urls.py original
    final url = Uri.parse(ApiConfig.endpoint('api/desafios/siguiente/')); 
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el desafío: ${response.body}');
    }
  }

  // POST /api/desafios/usuario/
  Future<void> crearDesafioUsuario({required int desafioId, required String estado}) async {
    // ▼▼▼ CORRECCIÓN AQUÍ ▼▼▼
    final url = Uri.parse(ApiConfig.endpoint('api/desafios/usuario/')); 
    final headers = await _getHeaders();
    final body = jsonEncode({
      'desafio': desafioId,
      'estado': estado,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 201) {
      throw Exception('Error al registrar el desafío: ${response.body}');
    }
  }

  // GET /api/desafios/usuario/
  Future<List<dynamic>> getMisDesafios() async {
    // ▼▼▼ CORRECCIÓN AQUÍ ▼▼▼
    final url = Uri.parse(ApiConfig.endpoint('api/desafios/usuario/')); 
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      // Esta es la excepción que estás viendo en tu log
      throw Exception('Error al obtener el historial de desafíos: ${response.body}');
    }
  }

  // GET /api/desafios/insignias/
  Future<List<dynamic>> getMisInsignias() async {
    // ▼▼▼ CORRECCIÓN AQUÍ ▼▼▼
    final url = Uri.parse(ApiConfig.endpoint('api/desafios/insignias/')); 
    final headers = await _getHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener las insignias: ${response.body}');
    }
  }
}