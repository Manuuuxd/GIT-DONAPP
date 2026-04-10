import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../campana/configurar_encuesta_screen.dart';
import '../campana/encuesta.dart';
import '../campanias/campanias_screen.dart';
import '../home_screen.dart';

// Pantalla de ejemplo a la que se puede navegar

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  final _chatController = InMemoryChatController();
  Timer? _inactivityTimer; // 👈 Timer para inactividad

  final Set<String> tagsValidas = {
    "NONE",
    "AGENDA_REQUEST",
    "AGENDA_RECOMMENDATION",
    "CONTACT_AGENT",
    "END"
  };
  @override
  void initState() {
    super.initState();
    resetInactivityTimer(); // 👈 inicia el timer al abrir la pantalla
  }
  @override
  void dispose() {
    _chatController.dispose();
    _inactivityTimer?.cancel();
    super.dispose();
  }
  void resetInactivityTimer() {
    _inactivityTimer?.cancel();
    //CAMBIAR A 5 MINUTOS LUEGO.
    _inactivityTimer = Timer(const Duration(seconds: 25), () {
      _chatController.insertMessage(TextMessage(
        id: '${Random().nextInt(100000)}',
        authorId: 'bot',
        createdAt: DateTime.now().toUtc(),
        text: '⚠️ La conversación ha expirado por inactividad.',
      ));
    });
  }


  // Función genérica para ejecutar acciones
  String  runAction(
      String action,
      String? data, {
        Message? processingMessage,
      }) {
    // Construimos el widget según la acción
    Widget widgetMessage = const Text('Procesando...', style: TextStyle(fontSize: 16));

    switch (action) {
      case 'NONE':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)), ],
        );
        break;
      case 'AGENDA_REQUEST':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)), ],
        );
        break;
      case 'AGENDA_RECOMMENDATION':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)), ],
        );
        break;
      case 'CONTACT_AGENT':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Se ha enviado tu número al ejecutivo. Pronto se pondrá en contacto contigo.",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ElevatedButton(
              onPressed: () async {
                // Llamada a la URL del backend para notificar el teléfono
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');

                final response = await http.post(
                  Uri.parse(ApiConfig.endpoint('api/chat/conexionTelefono/')),
                  headers: {
                    'Content-Type': 'application/json',
                    if (token != null) 'Authorization': 'Bearer $token',
                  },
                  body: jsonEncode({'telefono': data}), // suponiendo que 'data' contiene el teléfono
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ejecutivo notificado correctamente.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ejecutivo notificado .')),
                  );
                }
              },
              child: const Text("Notificar al ejecutivo"),
            ),
          ],
        );
        break;
      case 'END':
      // Insert message immediately (with final bot text)
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // Insertamos un widget de feedback como nuevo mensaje
                final feedbackController = TextEditingController();

                final feedbackWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Déjanos tu comentario:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Escribe tu comentario aquí...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final feedback = feedbackController.text.trim();
                        if (feedback.isNotEmpty) {
                          // Enviar feedback al backend
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            final token = prefs.getString('authToken');

                            final response = await http.post(
                              Uri.parse(ApiConfig.endpoint('api/chat/feedback/')),
                              headers: {
                                'Content-Type': 'application/json',
                                if (token != null) 'Authorization': 'Bearer $token',
                              },
                              body: jsonEncode({'comment': feedback}),
                            );

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(response.statusCode == 200
                                    ? 'Gracias por tu feedback'
                                    : 'Error enviando feedback: ${response.statusCode}'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error enviando feedback: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Enviar'),
                    ),
                  ],
                );

                // Insertamos el widget en el chat como un mensaje
                _chatController.insertMessage(TextMessage(
                  id: '${Random().nextInt(100000)}',
                  authorId: 'bot',
                  createdAt: DateTime.now().toUtc(),
                  text: '', // opcional
                  metadata: {'widget': feedbackWidget},
                ));
              },
              child: const Text('Dejar comentario'),
            ),
          ],
        );

        break;


      default:

        widgetMessage = Text(data ?? 'Acción no reconocida: $action',
            style: const TextStyle(fontSize: 16));
    }

    // Insertamos el mensaje con metadata para indicar que tiene un widget
    final newMessage = TextMessage(
      id: processingMessage?.id ?? '${Random().nextInt(100000)}',
      authorId: 'bot',
      createdAt: DateTime.now().toUtc(),
      text: data ?? '',
      metadata: {
        'widget': widgetMessage, // Guardamos el widget en metadata
        'action': action,
      },
    );

    if (processingMessage != null) {
      _chatController.updateMessage(processingMessage, newMessage);
    } else {
      _chatController.insertMessage(newMessage);
    }
    resetInactivityTimer();
    return action;
  }
  void _showFeedbackPopup(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tu experiencia'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Déjanos tus comentarios sobre el chat'),
            const SizedBox(height: 12),
            TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe tu comentario aquí...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final feedback = feedbackController.text.trim();
              if (feedback.isNotEmpty) {
                // enviar feedback al backend...
              }
              Navigator.of(context).pop();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  Map<String, String?> extractActionData(dynamic message) {
    String rawText = '';

    // Si viene como JSON con data.response
    if (message is Map<String, dynamic>) {
      if (message['data'] is Map<String, dynamic>) {
        rawText = message['data']['response']?.toString() ?? '';
      } else {
        rawText = message['data']?.toString() ?? '';
      }
    } else if (message is String) {
      rawText = message;
    } else {
      rawText = message.toString();
    }

    // 🔹 Extraer el texto entre 'model' y '[ACTION: ...]'
    final regex = RegExp(r'model\s*(.*?)\s*\[ACTION:', dotAll: true, caseSensitive: false);
    final match = regex.firstMatch(rawText);

    final extractedText = match?.group(1)?.trim() ?? rawText.trim();
    final regex2 = RegExp(r'\[ACTION:\s*(\w+)\]', dotAll: true, caseSensitive: false);
    final matchaction = regex2.firstMatch(rawText);
    final Action = matchaction?.group(1)?.trim() ?? rawText.trim();
    // Retornamos siempre la acción 'message' y el texto limpio
    return {
      'action': Action,
      'data': extractedText,
      'textBefore': extractedText,
    };
  }

  // Send message to backend
  Future<void> sendMessageToBackend(String text, BuildContext context)  async {
    // Insertar mensaje del usuario
    _chatController.insertMessage(TextMessage(
      id: '${Random().nextInt(100000)}',
      authorId: 'user1',
      createdAt: DateTime.now().toUtc(),
      text: text,
    ));

    resetInactivityTimer();

    final processingMessage = CustomMessage(
      id: '${Random().nextInt(100000)}',
      authorId: 'bot',
      createdAt: DateTime.now().toUtc(),
      metadata: {'text': 'Procesando...'},
    );
    _chatController.insertMessage(processingMessage);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final response = await http.post(
        Uri.parse(ApiConfig.endpoint('api/chat/chatbot/')),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': text}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al comunicarse con el backend: ${response.statusCode}');
      }

      final jsonResponse = jsonDecode(response.body);
      print("✅ Respuesta completa del backend: $jsonResponse");


      // 🔹 Ahora trabajamos con "response" directo del backend
      final actions = jsonResponse['actions'] as List<dynamic>;

      print("Actions??? :  $actions");

      final firstAction = actions.isNotEmpty ? actions.first as Map<String, dynamic> : {};

      print("firstaction??? :  $firstAction");
      final rawResponse = firstAction['data'] is Map<String, dynamic>
          ? firstAction['data']['response']?.toString() ?? ''
          : firstAction['data']?.toString() ?? '';

      print("total :  $rawResponse");

      // Extraemos acción y datos del texto
      final parsed = extractActionData(firstAction);
      print("parsed :  $parsed");
      final action = parsed['action'] ?? 'send_message';
      final data = parsed['data'] ?? rawResponse;


      // Insertar mensaje en el chat

      final returnedAction = runAction(action, data, processingMessage: processingMessage);
      print("accion supuesta: $returnedAction");
      // ✅ If END, trigger popup here
      if (returnedAction == 'END') {
        _showFeedbackPopup(context);
      }

    } catch (e) {
      _chatController.insertMessage(TextMessage(
        id: '${Random().nextInt(100000)}',
        authorId: 'bot',
        createdAt: DateTime.now().toUtc(),
        text: 'Error: $e',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Chatbot Usuario"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
        ),
        body: Chat(
          chatController: _chatController,
          currentUserId: 'user1',
          resolveUser: (id) async => User(id: id, name: 'John Doe'),
          onMessageSend: (text) => sendMessageToBackend(text, context),
          builders: Builders(
            textMessageBuilder: (
                context,
                message,
                messageWidth, {
                  MessageGroupStatus? groupStatus,
                  required bool isSentByMe,
                }) {
              // Check if the message has custom metadata
              if (message.metadata != null && message.metadata!['widget'] != null) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: message.metadata!['widget'] as Widget,
                );
              }

              // Default case: use the default text message builder
              return Align(
                alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(maxWidth: 250),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.text ?? '',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            },
          ),
        )
    );

  }
}
