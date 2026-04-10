import 'dart:convert';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


Future<Map<String, dynamic>> otorgarLogro(String token, String slug) async {
  final url = ApiConfig.endpoint('api/logros/otorgar-logro/');
  if (token.isEmpty) return {'status': 'sin_token'};
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'slug_key': slug}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception('Error otorgando logro');
  }
}

Future<void> mostrarDialogoLogro(BuildContext context, Map<String, dynamic> respuesta) async {
  String mensaje;

  if (respuesta['status'] == 'unlocked') {
    mensaje = "¡Has desbloqueado un nuevo logro: ${respuesta['achievement_name']}!";
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logro'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  } else if (respuesta['status'] == 'in_progress') {
    mensaje = "Progreso del logro '${respuesta['achievement_name']}' actualizado: ${respuesta['progress']}/${respuesta['achievement']['target_count']}.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }
}
