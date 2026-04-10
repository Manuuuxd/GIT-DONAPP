// lib/screens/trivia/question_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/MensajesApoyoMoral.dart';
import '../../data/MensajesApoyoMoralFalla.dart';
import '../../models/newtrivia.dart';
import '../../models/question.dart';
import '../Usuario/getlevel.dart';
import 'result_screen.dart';

// Importamos tu widget de tarjeta de pregunta original
import '../../widgets/trivia/question_card.dart'; 

// ----- Modelos de UI para el Chat -----
enum _ChatItemType { botQuestion, botFeedback, userReply }

abstract class _ChatItem {
  final _ChatItemType type;
  _ChatItem(this.type);
}

class _QuestionItem extends _ChatItem {
  final Question question;
  final String botAvatar; // CA04: Avatar para esta pregunta
  _QuestionItem(this.question, this.botAvatar) : super(_ChatItemType.botQuestion);
}

class _FeedbackItem extends _ChatItem {
  final String message;
  final bool isCorrect;
  final String botAvatar; // CA04: Avatar para este feedback
  _FeedbackItem(this.message, this.isCorrect, this.botAvatar) : super(_ChatItemType.botFeedback);
}

class _UserReplyItem extends _ChatItem {
  final String text;
  _UserReplyItem(this.text) : super(_ChatItemType.userReply);
}
// ----- Fin de Modelos de UI -----


class QuestionScreen extends StatefulWidget {
  final String dificultad;
  const QuestionScreen({super.key, required this.dificultad});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> with TickerProviderStateMixin {
  // --- Lógica de tu backend (SIN CAMBIOS) ---
  List<Question> questions = [];
  List<AnswerRecord> answersToSend = [];
  Map<String, int> statistics = {};
  int currentQuestionIndex = 0;
  int wrongAnswers = 0;
  int score = 0;
  bool isLoading = true;
  int? nivelUsuario;
  MessageProvider messageProvider = MessageProvider();
  FailMessageProvider failMessageProvider = FailMessageProvider();
  
  // --- Estado de la UI de Chat (NUEVO) ---
  final List<_ChatItem> _chatItems = [];
  final ScrollController _scrollController = ScrollController();
  bool _isBotTyping = true;
  bool _buttonsDisabled = false;
  String _currentBotAvatar = 'assets/images/pensativo.png'; // Avatar por defecto

  // --- CA02: Lógica del Temporizador Sutil ---
  AnimationController? _timerController;
  final int _timerDuration = 15; // 15 segundos por pregunta

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _timerDuration),
    );
    _timerController!.addStatusListener(_onTimerEnd);
    
    _initializeTrivia();
  }

  @override
  void dispose() {
    _timerController?.removeStatusListener(_onTimerEnd);
    _timerController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Lógica de Backend (SIN CAMBIOS) ---
  Future<void> _initializeTrivia() async {
    print('🧠 Iniciando trivia...');
    try {
      nivelUsuario = await fetchUserLevel();
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('authToken') ?? '';
      final String apiUrl = ApiConfig.endpoint("api/trivia/sessions/answers/");
      
      final initialPayload = {
        "record": [
          {"area": "Requisitos para donar", "correcta": false},
          {"area": "Compatibilidad sanguínea", "correcta": false},
          {"area": "Proceso de donación", "correcta": false},
          {"area": "Frecuencia permitida", "correcta": false},
          {"area": "Mitos y verdades", "correcta": false}
        ],
        "statistics": {
          "Requisitos para donar": 3,
          "Compatibilidad sanguínea": 3,
          "Proceso de donación": 3,
          "Frecuencia permitida": 3,
          "Mitos y verdades": 3
        },
        "dificultad": getNombreNivel(nivelUsuario ?? 1),
        "n": 5
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $accessToken'},
        body: jsonEncode(initialPayload),
      );

      print('📥 Código de respuesta: ${response.statusCode}');
      if (response.statusCode == 200) {
        final decoded = utf8.decode(response.bodyBytes);
        final data = jsonDecode(decoded);
        final List<Question> loaded = parseQuestionsFromJson(data["preguntas"]);
        statistics = Map<String, int>.from(data["nuevas_estadisticas"]);
        await messageProvider.loadMessages();
        await failMessageProvider.loadFailMessages();
        setState(() {
          questions = loaded..shuffle();
          isLoading = false;
        });
        print('🟢 Trivia lista para mostrarse');
        _startChatFlow(); 
      } else {
        print('❌ Falló la carga de preguntas: ${response.statusCode}');
        print('🧾 CUERPO DEL ERROR (DJANGO): ${response.body}');
        setState(() => isLoading = false);
      }
    } catch (e, stack) {
      print('💥 Error inesperado: $e');
      print('📉 Stacktrace:\n$stack');
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendFinalAnswers() async { /* Tu lógica SIN CAMBIOS */ }
  
  List<Question> parseQuestionsFromJson(List<dynamic> data) {
    try {
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      print("Error al parsear preguntas: $e");
      return []; // Devuelve lista vacía en error
    }
  }

  String getNombreNivel(int nivel) {
    if (nivel <= 3) return "Inicial";
    if (nivel >= 4 && nivel <= 6) return "Avanzado";
    if (nivel >= 7) return "Experto";
    return "Inicial"; // Valor por defecto
  }
  // --- Fin Lógica de Backend ---


  // --- Función de Traducción (V/F) ---
  String _traducirParaUI(String texto) {
    if (texto.toLowerCase() == 'true') {
      return 'Verdadero';
    }
    if (texto.toLowerCase() == 'false') {
      return 'Falso';
    }
    return texto; 
  }
  // --- Fin Función de Traducción ---


  // --- Lógica del Flujo de Chat ---
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTimer() {
    _timerController?.reset();
    _timerController?.forward();
  }

  void _onTimerEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _timeOutAnswer();
    }
  }

  void _timeOutAnswer() {
    if (_buttonsDisabled) return; 
    
    setState(() {
      _currentBotAvatar = 'assets/images/dormido.png';
      _isBotTyping = false;
    });

    answerQuestion(null);
  }

  void _startChatFlow() async {
    if (questions.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isBotTyping = false;
      _currentBotAvatar = 'assets/images/pensativo.png'; 
      _chatItems.add(_QuestionItem(questions[currentQuestionIndex], _currentBotAvatar));
    });
    _scrollToBottom();
    _startTimer(); 
  }

  // Lógica de respuesta (SIN CAMBIOS EN EL BACKEND)
  void answerQuestion(String? selected) async {
    if (_buttonsDisabled) return; 

    _timerController?.stop();
    setState(() {
      _buttonsDisabled = true;
      if (selected != null) {
        _chatItems.add(_UserReplyItem(_traducirParaUI(selected)));
      } else {
        _chatItems.add(_FeedbackItem("¡Se acabó el tiempo!", false, _currentBotAvatar));
      }
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 400));

    final question = questions[currentQuestionIndex];
    final isCorrect = (selected != null) && (question.answer == selected);
    answersToSend.add(AnswerRecord(area: question.area, correcta: isCorrect));
    if (isCorrect) {
      score++;
    } else {
      wrongAnswers++;
    }

    setState(() {
      _isBotTyping = true;
      _currentBotAvatar = isCorrect ? 'assets/images/heroe.png' : 'assets/images/lloron.png';
    });
    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      final feedbackMessage = isCorrect
          ? messageProvider.getRandomMessageForScore(score)
          : failMessageProvider.getRandomMessageForFails(wrongAnswers);
      _chatItems.add(_FeedbackItem(feedbackMessage, isCorrect, _currentBotAvatar));
      _isBotTyping = false;
    });
    _scrollToBottom();
    await Future.delayed(const Duration(milliseconds: 400));

    if (!isCorrect) {
      setState(() { 
        _isBotTyping = true;
        _currentBotAvatar = 'assets/images/facilito.png'; 
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      setState(() {
        final explanation = "Respuesta correcta: ${_traducirParaUI(question.answer)}\n\n${question.explicacion}";
        _chatItems.add(_FeedbackItem(explanation, false, _currentBotAvatar)); 
        _isBotTyping = false;
      });
      _scrollToBottom();
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final isLast = currentQuestionIndex == questions.length - 1;
    if (isLast) {
      await Future.delayed(const Duration(milliseconds: 1000));
      _sendFinalAnswers();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: score,
            total: questions.length,
            nivel: getNombreNivel(nivelUsuario ?? 1),
            avatarFinal: _currentBotAvatar, 
          ),
        ),
      );
    } else {
      setState(() { 
        _isBotTyping = true;
        _currentBotAvatar = 'assets/images/pensativo.png'; 
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      setState(() {
        currentQuestionIndex++;
        _chatItems.add(_QuestionItem(questions[currentQuestionIndex], _currentBotAvatar));
        _isBotTyping = false;
        _buttonsDisabled = false; 
      });
      _scrollToBottom();
      _startTimer(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'No se pudieron cargar las preguntas. Revisa tu conexión o el estado del servidor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trivia'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: 
            AnimatedBuilder(
              animation: _timerController!,
              builder: (context, child) {
                return LinearProgressIndicator(
                  value: 1.0 - _timerController!.value,
                  backgroundColor: theme.colorScheme.surfaceVariant,
                  color: theme.colorScheme.primary,
                );
              },
            ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _chatItems.length,
              itemBuilder: (context, index) {
                final item = _chatItems[index];
                switch (item.type) {
                  case _ChatItemType.botQuestion:
                    return _buildQuestionBubble(item as _QuestionItem, theme);
                  case _ChatItemType.botFeedback:
                    return _buildBotBubble(item as _FeedbackItem, theme);
                  case _ChatItemType.userReply:
                    return _buildUserBubble(item as _UserReplyItem, theme);
                }
                return const SizedBox.shrink(); 
              },
            ),
          ),
          if (_isBotTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  _Avatar(avatarPath: _currentBotAvatar, size: 40), // Avatar
                  const SizedBox(width: 12),
                  Text(
                    "Gotita está escribiendo...",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- Widgets de Burbujas de Chat ---

  Widget _buildQuestionBubble(_QuestionItem item, ThemeData theme) {
    return _BotBubbleContainer(
      avatarPath: item.botAvatar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reutilizamos tu widget 'QuestionCard' original.
          QuestionCard(question: item.question),
          const SizedBox(height: 16),
          ...item.question.options
              .where((opt) => opt != "N/A")
              .map((opt) => _AnswerChatButton(
                text: _traducirParaUI(opt), // Muestra "Verdadero"
                isDisabled: _buttonsDisabled,
                onTap: () => answerQuestion(opt), // Envía "True"
              )),
        ],
      ),
    );
  }

  Widget _buildBotBubble(_FeedbackItem item, ThemeData theme) {
    Color textColor = theme.colorScheme.onSurface;
    if (item.isCorrect) {
      textColor = theme.brightness == Brightness.dark ? Colors.green.shade200 : Colors.green.shade800;
    } else if (item.message.startsWith("Respuesta correcta:")) {
      textColor = theme.colorScheme.onSurfaceVariant;
    } else {
      textColor = theme.brightness == Brightness.dark ? Colors.red.shade200 : Colors.red.shade800;
    }

    return _BotBubbleContainer(
      avatarPath: item.botAvatar,
      child: Text(
        item.message,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildUserBubble(_UserReplyItem item, ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: Card(
        color: theme.colorScheme.primary, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: const Radius.circular(4),
          ),
        ),
        margin: const EdgeInsets.only(bottom: 12, left: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            item.text, // Aquí ya viene traducido ("Verdadero")
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}

// CA04: Avatar de la Gotita (Bot)
class _Avatar extends StatelessWidget {
  final String avatarPath;
  final double size; // Hacemos el tamaño variable
  const _Avatar({required this.avatarPath, this.size = 40.0}); // Tamaño por defecto 40

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Padding para que no se pegue al borde
        child: Image.asset(avatarPath), 
      ),
    );
  }
}

// CA04: Contenedor para burbujas del Bot (con Avatar)
class _BotBubbleContainer extends StatelessWidget {
  final Widget child;
  final String avatarPath;
  const _BotBubbleContainer({required this.child, required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ▼▼▼ ¡CAMBIO! El avatar ahora es más grande ▼▼▼
        _Avatar(avatarPath: avatarPath, size: 40), 
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            // Quitamos el 'right: 40' para que la burbuja sea más ancha
            margin: const EdgeInsets.only(bottom: 12), 
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

// CA01: Botón de respuesta estilo Rootd/chat
class _AnswerChatButton extends StatelessWidget {
  final String text;
  final bool isDisabled;
  final VoidCallback onTap;

  const _AnswerChatButton({required this.text, required this.isDisabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: OutlinedButton(
        onPressed: isDisabled ? null : onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.primary.withOpacity(isDisabled ? 0.3 : 0.8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text, // <-- Aquí se muestra el texto traducido
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w500,
              color: isDisabled ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
            )
          ),
        ),
      ),
    );
  }
}