import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';


Future<Uint8List?> exportWidgetToImage(GlobalKey key) async {
  try {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch (e) {
    print("Error exportando imagen: $e");
    return null;
  }
}


class ResumenDonante extends StatelessWidget {
  final String avatar;
  final int confianza;
  final int miedo;
  final bool viaje;
  final bool medicacion;
  final GlobalKey keyRepaint;

  const ResumenDonante({
    super.key,
    required this.avatar,
    required this.confianza,
    required this.miedo,
    required this.viaje,
    required this.medicacion,
    required this.keyRepaint,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: keyRepaint,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Resumen de tu simulación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              child: Text(avatar), // aquí puedes poner la imagen del avatar si la tienes
            ),
            const SizedBox(height: 16),
            Text('Nivel de confianza: $confianza'),
            Text('Nivel de miedo: $miedo'),
            Text('Viajó al extranjero: ${viaje ? "Sí" : "No"}'),
            Text('Usa medicamentos: ${medicacion ? "Sí" : "No"}'),
          ],
        ),
      ),
    );
  }
}