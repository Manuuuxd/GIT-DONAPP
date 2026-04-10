// lib/services/session_manager.dart

import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _guestKey = 'is_guest_user';

  // Marca al usuario como invitado y limpia tokens de sesión real
  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestKey, isGuest);
    if (isGuest) {
      await prefs.remove('authToken');
      await prefs.remove('refreshToken');
    }
  }

  // Revisa si la sesión actual es de un invitado
  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestKey) ?? false;
  }

  // Limpia la sesión completa (para logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('refreshToken');
    await prefs.remove(_guestKey);
  }
}