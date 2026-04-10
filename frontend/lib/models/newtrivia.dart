class AnswerRecord {
  final String area;
  final bool correcta;

  AnswerRecord({required this.area, required this.correcta});

  Map<String, dynamic> toJson() => {
    'area': area,
    'correcta': correcta,
  };
}