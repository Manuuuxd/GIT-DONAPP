import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'dart:convert';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:donapp_android/screens/Usuario/otorgar_logro.dart';


Future<int?> fetchUserLevel() async {
  final String nivelUrl = ApiConfig.endpoint("api/users/me/nivel/");
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) return null;

    final response = await http.get(
      Uri.parse(nivelUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final nivel = int.parse(response.body);
      return nivel;
    } else {
      print('Error: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Excepción: $e');
    return null;
  }
}

// Comprobamos el nivel actual y solicitamos el logro si es necesario para este y todos los niveles anteriores
Future<void> checkAndRequestLevelAchievement(context,int nivel) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  if (token == null) return;

  // Mapeo de niveles a slugs de logros
  final nivelToSlug = {
    1: "donante_novato",
    2: "aprendiz_de_sangre",
    3: "candidato_ideal",
    4: "explorador_hematico",
    5: "aliado_del_banco",
    6: "experto_en_componentes",
    7: "embajador_de_la_vida",
    8: "guardian_del_frigorifico",
    9: "mentor_de_donantes",
    10: "héroe_universal"
  };

  // Iteramos sobre los niveles y solicitamos los logros correspondientes
  for (var entry in nivelToSlug.entries) {
    if (nivel >= entry.key) {
      final respuesta = await otorgarLogro(token, entry.value);
      await mostrarDialogoLogro(context, respuesta);
      // Aquí podrías manejar la respuesta si es necesario
    }
  }
}



