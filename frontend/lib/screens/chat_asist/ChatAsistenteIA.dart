// chat_asistente.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Chat UI
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';

// Config API
import 'package:donapp_android/CONFIG/api_config.dart';

// Pantallas
import '../admin/admin_dashboard_screen.dart';
import '../admin/filtro_usuarios.dart' as usuarios;
import '../campanias/campanias_screen.dart';
import '../campanias/crear_campania_screen.dart';
import '../campana/encuesta.dart';
import '../estadisticas_camp/stats_page.dart';

class ChatAsistente extends StatefulWidget {
  const ChatAsistente({super.key});
  @override
  State<ChatAsistente> createState() => _ChatAsistenteState();
}

class _ChatAsistenteState extends State<ChatAsistente> {
  final _chatController = InMemoryChatController();

  // Acciones textuales permitidas cuando viene respuesta "plana"
  final Set<String> tagsValidas = {
    'campaign_effectiveness',
    'create_campaign',
    'create_poll',
    'functions',
    'get_campaign_link',
    'message_effectiveness',
    'register_donation',
    'search_campaign',
    'send_message',
    'assistant',
  };

  // ---- Cola de navegación (evita que espere otra acción del usuario) ----
  Map<String, dynamic>? _pendingNav;
  bool _navScheduled = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  // Encola una navegación para ejecutarla post-frame
  void _scheduleNav(Map<String, dynamic> data) {
    _pendingNav = data;
    if (_navScheduled || !mounted) return;
    _navScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _performPendingNav();
    });
  }

  Future<void> _performPendingNav() async {
    _navScheduled = false;
    final data = _pendingNav;
    _pendingNav = null;
    if (data == null || !mounted) return;

    // Casteos seguros (LinkedMap -> Map<String,dynamic>)
    final type = (data['type'] ?? '').toString();
    final target = (data['target'] ?? '').toString();
    final payload = (data['payload'] is Map)
        ? Map<String, dynamic>.from(data['payload'] as Map)
        : <String, dynamic>{};
    final form = (payload['form'] is Map)
        ? Map<String, dynamic>.from(payload['form'] as Map)
        : <String, dynamic>{};
    final query = (payload['query'] is Map)
        ? Map<String, dynamic>.from(payload['query'] as Map)
        : <String, dynamic>{};

    debugPrint('🚦 NAV -> $type::$target | payload=$payload');

    // === Navegaciones ===
    if (type == 'abrir_formulario' && target == 'nueva_campania') {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? '';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CrearCampaniaScreen(jwtToken: token, initialForm: form),
        ),
      );
      return;
    }

    if (type == 'abrir_formulario' && target == 'mensaje_directo') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
      return;
    }

    if (type == 'abrir_vista' && target == 'usuarios_lista') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const usuarios.FiltroUsuariosScreen(),
          settings: RouteSettings(arguments: query),
        ),
      );
      return;
    }

    if (type == 'abrir_vista' && target == 'campanias_activas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CampaniasScreen()),
      );
      return;
    }

    if (type == 'abrir_vista' && target == 'panel_metricas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StatsShell()),
      );
      return;
    }

    if (type == 'abrir_vista' && target == 'encuestas_activas') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EncuestaApp()),
      );
      return;
    }

    debugPrint('❓ NAV desconocida: $type::$target');
  }

  // Encolar (no navegar aquí)
  Future<void> _executeAssistantAction(Map data) async {
    final safe = (data is Map)
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    debugPrint('🧭 executeAssistantAction (enqueue) $safe');
    _scheduleNav(safe);
  }

  // ---------- Widgets por acción textual ----------
  void runAction(String action, String? data, {Message? processingMessage}) {
    Widget widgetMessage =
        const Text('Procesando...', style: TextStyle(fontSize: 16));

    switch (action) {
      case 'get_campaign_link':
        widgetMessage =
            Text(data ?? 'Link no disponible', style: const TextStyle(fontSize: 16));
        break;

      case 'create_campaign':
        widgetMessage = Text(
          data ?? 'Puedes crear tu campaña desde el panel',
          style: const TextStyle(fontSize: 16),
        );
        break;

      case 'create_poll':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => EncuestaApp()),
              ),
              child: const Text('Ir a Campañas'),
            ),
          ],
        );
        break;

      case 'functions':
      case 'message_effectiveness':
      case 'register_donation':
        widgetMessage = Text(data ?? '', style: const TextStyle(fontSize: 16));
        break;

      case 'search_campaign':
        widgetMessage = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data != null && data.isNotEmpty)
              Text(data, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampaniasScreen()),
              ),
              child: const Text('Ir a Campañas'),
            ),
          ],
        );
        break;

      case 'send_message':
      default:
        widgetMessage = Text(data ?? '', style: const TextStyle(fontSize: 16));
    }

    final bubble = TextMessage(
      id: processingMessage?.id ?? '${Random().nextInt(100000)}',
      authorId: 'bot',
      createdAt: DateTime.now().toUtc(),
      text: data ?? '',
      metadata: {'widget': widgetMessage, 'action': action},
    );

    if (processingMessage != null) {
      _chatController.updateMessage(processingMessage, bubble);
    } else {
      _chatController.insertMessage(bubble);
    }
  }

  // ---------- Parser de [Action: XYZ] ----------
  Map<String, String?> extractActionData(String message) {
    final actionRegex =
        RegExp(r'\[\s*action\s*:\s*(\w+)\s*\]', caseSensitive: false);
    final m = actionRegex.firstMatch(message);

    if (m != null) {
      final action = m.group(1);
      final parts = message.split(actionRegex);
      final before = parts.isNotEmpty ? parts[0].trim() : '';
      final after = parts.length > 1 ? parts[1].trim() : '';
      return {
        'action': action,
        'data': (after.isNotEmpty ? after : before),
        'textBefore': before,
      };
    }
    return {'action': 'send_message', 'data': message, 'textBefore': message};
  }

  // ---------- POST con Bearer/Token ----------
  Future<http.Response> _post(String url, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final uri = Uri.parse(url);

    final common = {'Content-Type': 'application/json; charset=utf-8'};

    // Bearer
    final h1 = Map<String, String>.from(common);
    if (token != null) h1['Authorization'] = 'Bearer $token';
    var r = await http.post(uri, headers: h1, body: jsonEncode(payload));
    if (r.statusCode != 401 || token == null) return r;

    // DRF TokenAuth (fallback)
    final h2 = Map<String, String>.from(common);
    h2['Authorization'] = 'Token $token';
    return await http.post(uri, headers: h2, body: jsonEncode(payload));
  }

  // ---------- intenta múltiples endpoints ----------
  Future<(http.Response, String)> _postToAny(
      List<String> endpoints, Map<String, dynamic> payload) async {
    http.Response? last;
    String? lastUrl;

    for (final ep in endpoints) {
      final url = ApiConfig.endpoint(ep);
      lastUrl = url;
      final res = await _post(url, payload);
      debugPrint('POST $url -> ${res.statusCode}');
      debugPrint('BODY: ${res.body}');
      if (res.statusCode == 200) return (res, url);
      last = res;
    }
    return (last!, lastUrl!);
  }

  // ---------- envío al backend ----------
  Future<void> sendMessageToBackend(String text) async {
    // burbuja del usuario
    _chatController.insertMessage(TextMessage(
      id: '${Random().nextInt(100000)}',
      authorId: 'user1',
      createdAt: DateTime.now().toUtc(),
      text: text,
    ));

    // burbuja "procesando"
    final processing = CustomMessage(
      id: '${Random().nextInt(100000)}',
      authorId: 'bot',
      createdAt: DateTime.now().toUtc(),
      metadata: {'text': 'Procesando...'},
    );
    _chatController.insertMessage(processing);

    try {
      final (res, usedUrl) = await _postToAny(
        ['api/chat/chatassistant/'], // agrega chatbot/ como fallback si quieres
        {'message': text},
      );

      if (res.statusCode != 200) {
        _chatController.updateMessage(
          processing,
          TextMessage(
            id: processing.id,
            authorId: 'bot',
            createdAt: DateTime.now().toUtc(),
            text: 'Backend ${res.statusCode} en $usedUrl:\n${res.body}',
          ),
        );
        return;
      }

      final jsonResp = jsonDecode(res.body);
      debugPrint('📦 respuesta backend: ${jsonEncode(jsonResp)}');

      // -------- Normalización ultra tolerante --------
      List<dynamic> acciones = [];

      if (jsonResp is Map && jsonResp['actions'] is List) {
        acciones = List<dynamic>.from(jsonResp['actions']);
      }

      if (acciones.isEmpty && jsonResp is Map && jsonResp['actions'] is Map) {
        acciones = [Map<String, dynamic>.from(jsonResp['actions'])];
      }

      if (acciones.isEmpty && jsonResp is Map && jsonResp['action'] is Map) {
        final a = Map<String, dynamic>.from(jsonResp['action']);
        if (a['type'] != null && a['target'] != null) {
          acciones = [a];
        } else {
          acciones = [
            {'action': 'assistant', 'data': a}
          ];
        }
      }

      if (acciones.isEmpty &&
          jsonResp is Map &&
          jsonResp['type'] != null &&
          jsonResp['target'] != null) {
        acciones = [Map<String, dynamic>.from(jsonResp)];
      }

      if (acciones.isEmpty &&
          jsonResp is Map &&
          jsonResp['response'] != null) {
        acciones = [
          {'action': 'send_message', 'data': jsonResp['response'].toString()}
        ];
      }

      if (acciones.isEmpty) {
        final fallback =
            (jsonResp['raw_model_response']?['output']?['response'] ?? '')
                .toString();
        acciones = [
          {'action': 'send_message', 'data': fallback}
        ];
      }

      debugPrint('🧾 acciones normalizadas: ${jsonEncode(acciones)}');

      bool replaced = false;

      for (final a in acciones) {
        debugPrint('🔎 acción item: $a');

        // Estándar: {"action":"assistant","data":{type,target,payload}}
        if (a is Map && a['action'] == 'assistant' && a['data'] is Map) {
          final dataMap = Map<String, dynamic>.from(a['data'] as Map);
          _executeAssistantAction(dataMap); // encola
          replaced = true;
          continue;
        }

        // Directo: {"type":"abrir_vista","target":"...","payload":{...}}
        if (a is Map && a['type'] != null && a['target'] != null) {
          _executeAssistantAction(Map<String, dynamic>.from(a)); // encola
          replaced = true;
          continue;
        }

        // Envuelto: {"action": {"type":...,"target":...}}
        if (a is Map && a['action'] is Map) {
          final inner = Map<String, dynamic>.from(a['action'] as Map);
          if (inner['type'] != null && inner['target'] != null) {
            _executeAssistantAction(inner); // encola
            replaced = true;
            continue;
          }
        }

        // Texto con [Action: XYZ]
        String raw;
        if (a is Map && a['data'] is Map) {
          raw = (a['data']['response'] ?? '').toString();
        } else if (a is Map) {
          raw = (a['data'] ?? '').toString();
        } else {
          raw = a.toString();
        }

        final parsed = extractActionData(raw);
        final action = (parsed['action'] ?? 'send_message')!;
        final data = parsed['data'] ?? raw;

        if (action.toLowerCase() == 'create_campaign') {
          runAction(
            'send_message',
            data.isNotEmpty ? data : 'Abriendo formulario de campaña',
            processingMessage: replaced ? null : processing,
          );
          _executeAssistantAction({
            'type': 'abrir_formulario',
            'target': 'nueva_campania',
            'payload': {'form': {}}
          });
          replaced = true;
          continue;
        }

        final safeAction = tagsValidas.contains(action) ? action : 'send_message';
        if (!replaced) {
          runAction(safeAction, data, processingMessage: processing);
          replaced = true;
        } else {
          runAction(safeAction, data);
        }
      }

      // Forzar flush de navegación después del frame actual
      if (mounted) {
        SchedulerBinding.instance
            .addPostFrameCallback((_) => _performPendingNav());
      }

      if (!replaced) {
        _chatController.updateMessage(
          processing,
          TextMessage(
            id: processing.id,
            authorId: 'bot',
            createdAt: DateTime.now().toUtc(),
            text: 'No hubo respuesta útil del backend',
          ),
        );
      }
    } catch (e) {
      _chatController.updateMessage(
        processing,
        TextMessage(
          id: processing.id,
          authorId: 'bot',
          createdAt: DateTime.now().toUtc(),
          text: 'Error: $e',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    final chatWidget = Chat(
      chatController: _chatController,
      currentUserId: 'user1',
      resolveUser: (id) async => User(id: id, name: 'John Doe'),
      onMessageSend: sendMessageToBackend,
      builders: Builders(
        textMessageBuilder: (
          context,
          message,
          messageWidth, {
          MessageGroupStatus? groupStatus,
          required bool isSentByMe,
        }) {
          final bubbleColor = isSentByMe ? Colors.blue[100] : Colors.grey[200];

          if (message.metadata != null && message.metadata!['widget'] != null) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: message.metadata!['widget'] as Widget,
            );
          }

          return Align(
            alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 250),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(message.text ?? '',
                  style: const TextStyle(fontSize: 16)),
            ),
          );
        },
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
      ),
      body: isWide
          ? Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                  ],
                ),
                child: Row(children: [Expanded(child: chatWidget)]),
              ),
            )
          : chatWidget,
    );
  }
}
