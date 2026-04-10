class Question {
  final String text;
  final String explicacion;
  final String area;
  final List<String> options; // Solo los textos de respuesta
  final String answer; // Respuesta correcta

  Question({
    required this.text,
    required this.explicacion,
    required this.area,
    required this.options,
    required this.answer,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final answers = json['answers'] as List<dynamic>? ?? [];

    // Extraer opciones
    final options = answers
        .map((a) => a['text']?.toString() ?? 'N/A')
        .toList();

    while (options.length < 3) {
      options.add("N/A");
    }

    // Buscar la respuesta correcta
    String correctAnswer = 'Vacío';
    for (var a in answers) {
      if (a['is_correct'] == true) {
        correctAnswer = a['text']?.toString() ?? 'Vacío';
        break;
      }
    }

    return Question(
      text: json['text']?.toString() ?? '',
      explicacion: json['explanation']?.toString() ?? '',
      area: json['area']?.toString() ?? '',
      options: options,
      answer: correctAnswer,
    );
  }
}
