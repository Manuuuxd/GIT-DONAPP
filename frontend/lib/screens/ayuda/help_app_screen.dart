import 'package:flutter/material.dart';

class HelpAppScreen extends StatelessWidget {
  const HelpAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        'q': '¿Qué hago si olvidé mi contraseña?',
        'a': 'En la seccion de inicio de sesión pueder apretar el boton de "¿Olvidaste tu contraseña?" para iniciar el proceso de cambio de contraseña.'
      },
      {
        'q': '¿Como agrego amigos?',
        'a': 'En tu perfil hay una sección donde puedes ver tus solicitudes de amistad y buscar a personas por su nombre de usuario.'
      },
      {
        'q': '¿Cómo obtengo puntos o XP?',
        'a': 'La forma principal de conseguir EXP es a traves de los juegos que tiene la App.'
      },
      {
        'q': '¿Cómo puedo ver si puedo donar?',
        'a': 'En el inicio puedes ir a "Donar ahora" para rellenar un formulario".'
      },
      {
        'q': '¿Que son los logros?',
        'a': 'Son las metas que uno puede ir cumpliendo a medida que uno va donando.'
      },
      {
        'q': '¿Que son los logros?',
        'a': 'Son las metas que uno puede ir cumpliendo a medida que uno va donando.'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Centro de Ayuda - App')),
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
