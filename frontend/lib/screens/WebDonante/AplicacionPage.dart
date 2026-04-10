import 'package:flutter/material.dart';
//import 'package:qr_flutter/qr_flutter.dart';
import 'package:donapp_android/screens/WebDonante/widgetswebdonante/Headerweb.dart';
import '../home/home_controller.dart';

class AplicacionPage extends StatelessWidget {
  final HomeController controller = HomeController();

  AplicacionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Column(
        children: [
          HomeHeaderweb(controller: controller),

          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 🖼️ Imagen promocional de la app
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/35f7c044-a478-4cf4-b6c5-67f1582fd541.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(width: 60),

                    // 📱 Sección con QR para descargar la app
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Descarga la app Donapp",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Escanea el código QR para instalar la aplicación en tu dispositivo móvil.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 🌀 QR dinámico (puede apuntar al enlace real de la app)
                          /*QrImageView(
                            data: 'https://play.google.com/store/apps/details?id=com.donapp',
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),*/

                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              // opcional: abrir directamente el enlace
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.open_in_new, color: Colors.white),
                            label: const Text(
                              "Abrir en Google Play",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
