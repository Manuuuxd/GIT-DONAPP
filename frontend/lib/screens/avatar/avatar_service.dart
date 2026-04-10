
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../CONFIG/api_config.dart';
import 'avatar_model.dart';
import 'package:donapp_android/colours/app_colors.dart';

class AvatarService {
  static const _kKey = 'donapp_avatar_v1';
  static const AvatarData _defaults = AvatarData(
    skinColor: Color(0xFFF4D1B5),
    shirtColor: Color(0xFF4DA1E5),
    accessory: Accessory.none,
  );

  /// Cargar avatar desde backend o local
  static Future<AvatarData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final baseUrl = ApiConfig.endpoint("api/avatar/");

    try {
      final res = await http.get(
        Uri.parse(baseUrl),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final avatar = AvatarData.fromMap({
          'skinColor': data['skin_color'],
          'shirtColor': data['shirt_color'],
          'accessory': data['accessory'],
        });

        // Guardar localmente también
        await prefs.setString(_kKey, avatar.toJson());
        return avatar;
      }
    } catch (_) {}

    // Si falla, usar local o defaults
    final raw = prefs.getString(_kKey);
    if (raw == null) return _defaults;
    return AvatarData.fromJson(raw);
  }

  /// Guardar avatar en backend y local
  static Future<void> save(AvatarData data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final baseUrl = ApiConfig.endpoint("api/avatar/");

    await prefs.setString(_kKey, data.toJson());

    try {
      await http.put(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          'skin_color': data.skinColor.value,
          'shirt_color': data.shirtColor.value,
          'accessory': data.accessory.name,
        }),
      );
    } catch (_) {
      // Si falla la conexión, al menos se conserva localmente
    }
  }
}