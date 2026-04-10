import 'package:flutter/material.dart';

class EstaditicasCampanasScreen extends StatefulWidget {
  const EstaditicasCampanasScreen({super.key});

  @override
  State<EstaditicasCampanasScreen> createState() => _EstaditicasCampanasState();
}

class _EstaditicasCampanasState extends State<EstaditicasCampanasScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Campañas'),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
      ),
      body: const Center(
        child: Text('Aquí van las estadísticas de campañas.'),
      ),
    );
  }
}