import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';


class CampaignNotifier {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final String apiBaseUrl;
  final String authToken;
  final GlobalKey<NavigatorState> navigatorKey;

  CampaignNotifier({
    required this.apiBaseUrl,
    required this.authToken,
    required this.navigatorKey,
  });

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        if (payload != null) {
          await _onSelectNotification(payload);
        }
      },
    );
  }

  Future<void> notifyCreatedCampaign(dynamic campania) async {
    // Obtener coordenadas de campaña
    final double? latCamp = (campania['latitud'] as num?)?.toDouble();
    final double? lngCamp = (campania['longitud'] as num?)?.toDouble();
    if (latCamp == null || lngCamp == null) {
      debugPrint('Campaña sin coordenadas, no notificar.');
      return;
    }

    // Obtener ubicación actual
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    // Calcular distancia en km
    final Distance distance = Distance();
    final double kmDistance = distance(
        LatLng(position.latitude, position.longitude),
        LatLng(latCamp, lngCamp)) / 1000;

    if (kmDistance <= 5) {
      await _showNotification(campania);
    } else {
      debugPrint('Campaña fuera del radio de 5km (distancia: $kmDistance km), no se notifica.');
    }
  }


  Future<void> _showNotification(dynamic campania) async {
    final int id = int.tryParse(campania['id']?.toString() ?? '0') ?? 0;
    final String nombre = campania['nombre'] ?? "Campaña cercana";
    final String direccion = (campania['direccion'] ?? "").toString().split(',').first;
    final String fecha = campania['fecha'] ?? "";

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'campaigns_channel',
      'Campañas',
      channelDescription: 'Notificaciones de campañas creadas',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      id,
      nombre,
      'Campaña en $direccion - Fecha: $fecha',
      platformChannelSpecifics,
      payload: jsonEncode(campania),
    );
  }

  Future<void> _onSelectNotification(String payload) async {
    final campaignData = jsonDecode(payload);
    navigatorKey.currentState?.pushNamed('/map', arguments: campaignData);
    debugPrint("Navegando a la pantalla de mapa con datos de campaña: $campaignData");
  }
}
