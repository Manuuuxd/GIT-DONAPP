// Archivo: appointment_service.dart (COMPLETO Y CORREGIDO)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';

// ... (Las clases DonationCenter y Appointment no cambian) ...
class DonationCenter {
  final int id;
  final String name;
  final String comuna;
  final String address;
  final String phone;

  DonationCenter({required this.id, required this.name, required this.comuna, required this.address, required this.phone});

  factory DonationCenter.fromJson(Map<String, dynamic> json) {
    return DonationCenter(
      id: json['id'],
      name: json['name'],
      comuna: json['comuna'],
      address: json['address'],
      phone: json['phone'] ?? '',
    );
  }
}

class Appointment {
  final int? id;
  final String rut;
  final String email;
  final String date;
  final String time;
  final int centerId;
  final String? centerName;
  final String? status;
  final String? cancellationReason;

  Appointment({
    this.id,
    required this.rut,
    required this.email,
    required this.date,
    required this.time,
    required this.centerId,
    this.centerName,
    this.status,
    this.cancellationReason,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      rut: json['rut'],
      email: json['email'],
      date: json['date'],
      time: json['time'],
      centerId: json['center']['id'],
      centerName: json['center']['name'],
      status: json['status'],
      cancellationReason: json['cancellation_reason'],
    );
  }

  Map<String, dynamic> toJson() {
    final formattedDate = _normalizeDate(date);
    final formattedTime = _normalizeTime(time);

    return {
      "rut": rut,
      "email": email,
      "date": formattedDate,
      "time": formattedTime,
      "center_id": centerId,
    };
  }

  String _normalizeDate(String dateStr) {
    if (dateStr.contains('T')) {
      return dateStr.split('T').first;
    }
    return dateStr;
  }

  String _normalizeTime(String timeStr) {
    try {
      String t = timeStr.trim().toUpperCase();
      final match = RegExp(r'^(\d{1,2}):(\d{2}) ?(AM|PM)?$').firstMatch(t);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        final ampm = match.group(3);
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        return "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00";
      }
      if (RegExp(r'^\d{2}:\d{2}$').hasMatch(t)) {
        return "$t:00";
      }
      return t;
    } catch (_) {
      return timeStr;
    }
  }
}


class AppointmentService {
  final String baseUrl = ApiConfig.endpoint("api/appointments");

  // --- 🌟 CAMBIO 1: Modificar fetchCenters 🌟 ---
  Future<List<DonationCenter>> fetchCenters({bool isGuest = false}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json', // Placeholder
    };

    // Si NO es invitado, busca y añade el token
    if (!isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("No hay tokens disponibles para usuario registrado");
      headers['Authorization'] = 'Bearer $token';
    }
    // Si es invitado, la llamada se hace sin token (endpoint público)

    final url = Uri.parse("$baseUrl/centers/");
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List data = jsonDecode(decoded);
      return data.map((e) => DonationCenter.fromJson(e)).toList();
    } else if (response.statusCode == 401) {
      // Si da 401 (No autorizado) incluso siendo invitado,
      // el problema es del backend (el endpoint no es público).
      throw Exception("No autorizado.");
    } else {
      throw Exception("Error al cargar centros: ${response.statusCode}");
    }
  }
  // --- FIN CAMBIO 1 ---

  // --- 🌟 CAMBIO 2: Modificar scheduleAppointment 🌟 ---
  Future<bool> scheduleAppointment(Appointment appt, {bool isGuest = false}) async {
    
    final Map<String, String> headers = {
      "Content-Type": "application/json",
    };

    // Si NO es invitado, busca y añade el token
    if (!isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) throw Exception("No hay tokens disponibles para usuario registrado");
      headers['Authorization'] = 'Bearer $token';
    }
    // Si es invitado, la llamada se hace sin token (endpoint público)
    
    final url = Uri.parse("$baseUrl/appointments/");

    try {
      final response = await http.post(
        url,
        headers: headers, // <-- Usa los headers dinámicos
        body: jsonEncode(appt.toJson()),
      );

      print("📡 POST $url (Invitado: $isGuest)");
      print("📤 Enviando: ${appt.toJson()}");
      print("📥 Respuesta ${response.statusCode}: ${response.body}");

      if (response.statusCode == 201) return true;
      if (response.statusCode == 400) {
        // Asumiendo que el 400 es por cita duplicada
        throw Exception("Ya existe una cita registrada con estos datos");
      }
      return false;
    } catch (e) {
      print("❌ Error en scheduleAppointment: $e");
      // Pasa el mensaje de error
      throw Exception("Error al agendar: $e");
    }
  }
  // --- FIN CAMBIO 2 ---

  // ... (fetchHistory y cancelAppointment no cambian) ...
  Future<List<Appointment>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) throw Exception("No hay tokens disponibles");

    final url = Uri.parse("$baseUrl/appointments/history/");
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final List data = jsonDecode(decoded);
      return data.map((e) => Appointment.fromJson(e)).toList();
    } else {
      throw Exception("Error al cargar historial: ${response.statusCode}");
    }
  }
  Future<bool> cancelAppointment(int appointmentId, String reason) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');

  if (token == null) throw Exception("No hay tokens disponibles");

  final url = Uri.parse("$baseUrl/appointments/$appointmentId/cancel/");
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({"reason": reason}),
  );

  return response.statusCode == 200;
  }
}