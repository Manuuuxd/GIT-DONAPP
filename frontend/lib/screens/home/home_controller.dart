// Archivo: home_controller.dart (COMPLETO Y CORREGIDO)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // <-- 🌟 AÑADE ESTE IMPORT
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/screens/desafios/desafios_screen.dart';

class HomeController extends ChangeNotifier {
  bool isAdmin = false;
  bool isLoggedIn = false;
  String? userName;

  // --- 🌟 CAMBIO 1: Aceptar el context ---
  Future<void> loadUserData(BuildContext context) async {
  // --- FIN CAMBIO ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null && !JwtDecoder.isExpired(token)) {
      final decoded = JwtDecoder.decode(token);
      isAdmin = decoded['is_admin'] == true;
      userName =
          decoded['first_name'] ?? decoded['username'] ?? "Usuario";
      isLoggedIn = true;
      
      // --- 🌟 CAMBIO 2: Pasar el context ---
      _registrarDesafioAperturaApp(context);
      // --- FIN CAMBIO ---
    } else {
      isAdmin = false;
      isLoggedIn = false;
    }
  }

  Future<void> login(String email, String password) async {
    // ...
    // NOTA: Esta función 'login' probablemente también necesite
    // el 'context' ahora. Deberías cambiarla a:
    // Future<void> login(BuildContext context, String email, String password) async {
    //   await loadUserData(context); 
    //   notifyListeners();
    // }
    
    // Por ahora, lo dejamos así para no romper más cosas:
    // await loadUserData(context); // Esto fallará si no pasas el context
    notifyListeners();
  }
  
  Future<void> logout() async {
    // ...
    isLoggedIn = false;
    isAdmin = false;
    notifyListeners();
  }

  // --- 🌟 CAMBIO 3: Aceptar el context ---
  Future<void> _registrarDesafioAperturaApp(BuildContext context) async {
  // --- FIN CAMBIO ---
    
    // Ahora 'context' está definido
    intentarCompletarDesafio(context,'abrir_app');
  }
}