import 'package:flutter/material.dart';

class HelpOrganizationScreen extends StatelessWidget {
  const HelpOrganizationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': '¿Qué es DonApp?',
        'a': 'DonApp es una aplicación chilena que busca aumentar la donación altruista de sangre entre jóvenes de 18 a 35 años, conectándolos de forma emocional y educativa con la causa.'
      },
      {
        'q': '¿Por qué nace DonApp?',
        'a': 'Surge ante el déficit nacional de donantes voluntarios (solo 22% del total) y la necesidad de reemplazar los canales tradicionales por soluciones digitales más cercanas.'
      },
      {
        'q': '¿Cuál es la diferencia con otras apps de donación?',
        'a': 'A diferencia de Blooders o Be The 1 Donor, DonApp no solo informa o agenda donaciones: busca transformar comportamientos y crear una comunidad de donantes fidelizados.'
      },
      {
        'q': '¿Con quién trabaja DonApp?',
        'a': 'El proyecto fue validado junto al Centro Metropolitano de Sangre, que colabora activamente en mejorar la comunicación y fidelización de donantes altruistas.'
      },
      {
        'q': '¿Qué tecnologías utiliza?',
        'a': 'La app está desarrollada con Flutter, integra inteligencia artificial para personalización, gamificación y notificaciones basadas en comportamiento del usuario.'
      },
      {
        'q': '¿Qué impacto busca generar?',
        'a': 'Promover la donación voluntaria y recurrente, educar con contenido científico, y conectar emocionalmente a las personas con el valor de donar sangre.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Centro de Ayuda - DonApp')),
      body: ListView.builder(
        itemCount: faqs.length,
        itemBuilder: (context, i) {
          final item = faqs[i];
          return ExpansionTile(
            title: Text(item['q']!),
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  item['a']!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
