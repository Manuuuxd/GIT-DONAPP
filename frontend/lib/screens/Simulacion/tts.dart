import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts flutterTts = FlutterTts();

Future<void> speakText(String text) async {
  await flutterTts.stop(); // detiene cualquier TTS anterior
  await flutterTts.speak(text);
}