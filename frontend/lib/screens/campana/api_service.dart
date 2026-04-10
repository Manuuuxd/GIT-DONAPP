import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final baseUrl = ApiConfig.endpoint("api/survey"); // ⚠️ cámbialo si usas otro host

  static Future<List<dynamic>> getSurveys() async {
    //final prefs = await SharedPreferences.getInstance();
    //final authToken = prefs.getString('authToken') ?? '';

    final response = await http.get(
      Uri.parse("$baseUrl/survey/"), // 👈 note trailing slash
    );
    //final response2 = await http.get(Uri.parse(ApiConfig.endpoint("api/survey/test/")));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar encuestas");
    }
  }

  static Future<Map<String, dynamic>> getSurveyDetail(int id) async {
    final response = await http.get(Uri.parse("$baseUrl/survey/$id/"));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Error al cargar encuesta");
    }
  }

  static Future<void> patchSegmentacion(int surveyId, Map<String, dynamic> data) async {

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await http.patch(
      Uri.parse("$baseUrl/survey/$surveyId/segment/"),

      headers: {"Content-Type": "application/json",
        if (token != null) 'Authorization': 'Bearer $token',},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception("Error al guardar segmentación");
    }
  }

  static Future<void> patchCanales(int surveyId, List<String> canales) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await http.patch(
      Uri.parse("$baseUrl/survey/$surveyId/channels/"),
      headers: {"Content-Type": "application/json",
        if (token != null) 'Authorization': 'Bearer $token',},
      body: jsonEncode({"channels": canales}),
    );
    if (response.statusCode != 200) {
      throw Exception("Error al guardar canales");
    }
  }

  static Future<void> postResponse(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse("$baseUrl/responses/"),
      headers: {"Content-Type": "application/json",
        if (token != null) 'Authorization': 'Bearer $token',},
      body: jsonEncode(data),
    );
    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode != 201) {
      throw Exception("Error al enviar respuesta");
    }
  }
}
