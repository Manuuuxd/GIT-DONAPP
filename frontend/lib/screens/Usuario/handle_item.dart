import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';


Future<Map<String, dynamic>> otorgarItem(String slug, {int cantidad = 1}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = ApiConfig.endpoint('api/logros/otorgar-item/');

  if (token.isEmpty) return {'status': 'sin_token'};

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'slug': slug,
      'cantidad': cantidad,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error otorgando ítem: ${response.body}');
  }
}

Future<Map<String, dynamic>> canjearItem(String slug, {int cantidad = 1}) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken') ?? '';
  final url = ApiConfig.endpoint('api/logros/canjear-item/');

  if (token.isEmpty) return {'status': 'sin_token'};

  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'slug': slug,
      'cantidad': cantidad,
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Error canjeando ítem: ${response.body}');
  }
}


Future <void> showItemDialog(BuildContext context, {
  required String title,
  required String message,
  required String imageAssetPath,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imageAssetPath,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported, size: 60, color: Colors.red),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    ),
  );
}
