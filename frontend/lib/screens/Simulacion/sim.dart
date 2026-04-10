  import 'dart:async';
import 'dart:developer';

import 'package:donapp_android/screens/Simulacion/exportimage.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle,SystemChrome,DeviceOrientation;
import 'package:flutter_tts/flutter_tts.dart';

import 'package:jenny/jenny.dart';

import '../schedule/schedule_screen.dart';
import 'project_view_component.dart';
class TtsDialogueView extends DialogueView {
  final FlutterTts flutterTts = FlutterTts();

  TtsDialogueView() {
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setSpeechRate(0.7);
    await flutterTts.setPitch(1.0);
    await flutterTts.setVolume(0.8);

    await flutterTts.awaitSpeakCompletion(true);
  }

  // Función auxiliar para dividir en frases manejables para el TTS:
  List<String> _chunkText(String text) {
    final sentences = text.split(RegExp(r'(?<=[\.\,\?\!])\s+'));
    final List<String> chunks = [];

    for (var sentence in sentences) {
      sentence = sentence.trim();
      if (sentence.isEmpty) continue;

      if (sentence.length > 200) {
        for (var i = 0; i < sentence.length; i += 200) {
          chunks.add(sentence.substring(
            i,
            (i + 200 < sentence.length) ? i + 200 : sentence.length,
          ));
        }
      } else {
        chunks.add(sentence);
      }
    }

    return chunks;
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    await flutterTts.stop();

    final fragments = _chunkText(line.text);

    for (final fragment in fragments) {
      await flutterTts.speak(fragment);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    return false;
  }

  @override
  FutureOr<void> onLineFinish(DialogueLine line) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}

class JennyGamePage extends StatefulWidget {
  const JennyGamePage({Key? key}) : super(key: key);

  @override
  State<JennyGamePage> createState() => _JennyGamePageState();
}

class _JennyGamePageState extends State<JennyGamePage> {
  late final JennyGame _game;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Inicializamos el juego solo si no se ha hecho aún
    if (!(_game != null)) {
      _game = JennyGame(appContext: context);
    }
  }


  @override
  void initState() {
    super.initState();
    _game = JennyGame(appContext: context);

    // Forzar landscape solo para este widget
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Restaurar orientaciones al salir
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),

          // Botón salir arriba a la derecha
          Positioned(
            top: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.pop(context); // vuelve a la pantalla principal
              },
              child: const Text("Salir"),
            ),
          ),
        ],
      ),
    );
  }
}



class JennyGame extends FlameGame {
  final BuildContext appContext;

  JennyGame({required this.appContext});

  bool avatarPlaced = false; 

  late Sprite seleccionSprite;
  late Sprite fueraCentroSprite;
  late Sprite registroSprite;
  late Sprite entrevista_medicaSprite;
  late Sprite zona_esperaSprite;
  late Sprite extraccionSprite;
  late Sprite recuperacionSprite;

  late Sprite beachBackgroundSprite;
  late Sprite girlSprite;
  late Sprite girlSurprisedSprite;
  late Sprite girlSwimwearSprite;
  late Sprite boySprite;
  late Sprite boySwimwearSprite;
  late Sprite protagonistSprite;

  late Sprite avatar1Sprite;
  late Sprite avatar2Sprite;
  late Sprite avatar3Sprite;
  late TtsDialogueView ttsDialogueView;
  late DialogueRunner dialogueRunner;

  YarnProject yarnProject = YarnProject();
  ProjectViewComponent projectViewComponent = ProjectViewComponent();

  @override
  FutureOr<void> onLoad() async {
    seleccionSprite = await loadSprite('Simulacion/Seleccion.png');
    fueraCentroSprite = await loadSprite('Simulacion/FueraCentroTransfusion.png');
    registroSprite =await loadSprite('Simulacion/Mostrador.png');
    entrevista_medicaSprite =await loadSprite('Simulacion/Entrevista.png');
    zona_esperaSprite = await loadSprite('Simulacion/SalaEspera.png');
    extraccionSprite = await loadSprite('Simulacion/ProtagonistaDonando.png');
    recuperacionSprite = await loadSprite('Simulacion/AlgunosSnacks.png');

    girlSprite = await loadSprite('avatar2.png');
    boySprite = await loadSprite('blood_drop_character.png');
    avatar1Sprite = await loadSprite('avatar1.png');
    avatar2Sprite = await loadSprite('avatar2.png');
    avatar3Sprite = await loadSprite('avatar3.png');

    String centroData = await rootBundle.loadString('assets/yarn/Centro.yarn');
    String startDialogueData = await rootBundle.loadString('assets/yarn/intro.yarn');
    String finalData = await rootBundle.loadString('assets/yarn/final.yarn');

    //String beachData = await rootBundle.loadString('assets/yarn/beach.yarn');
      //..parse(cafeData)
      //..parse(beachData);
      //
    ttsDialogueView = TtsDialogueView();
    protagonistSprite = avatar1Sprite;

    yarnProject.variables.setVariable(r'$player', '');
    yarnProject.variables.setVariable(r'$avatar', '');
    yarnProject.variables.setVariable(r'$confianza', 0);
    yarnProject.variables.setVariable(r'$miedo', 0);

    yarnProject.commands.addCommand0('avatarChosen', () {
      log("🔥 Jenny ejecutó avatarChosen");

      if (avatarPlaced) return;

      final varName = r'$player';
      if (!yarnProject.variables.hasVariable(varName)) {
        log("⚠️ No existe la variable $varName en el storage (hasVariable==false).");
        // DEBUG extra (intenta leer directamente):
        final raw = yarnProject.variables.getVariable(varName);
        log("DEBUG: getVariable($varName) -> $raw");
        return;
      }

      final playerChoice = yarnProject.variables.getStringValue(varName);
      log("🎯 Valor real en Jenny: $playerChoice");

      switch (playerChoice) {
        case 'avatar1':
          protagonistSprite = avatar1Sprite;
          break;
        case 'avatar2':
          protagonistSprite = avatar2Sprite;
          break;
        case 'avatar3':
          protagonistSprite = avatar3Sprite;
          break;
        default:
          log("⚠️ Valor inesperado en player: '$playerChoice'");
          return;
      }

      avatarPlaced = true;
      projectViewComponent.setAvatar(protagonistSprite);
    });

    yarnProject.commands.addCommand2('add', (String varName, num increment) {
      log(varName);
      final key = varName;
      final current = yarnProject.variables.getNumericValue(key);
      yarnProject.variables.setVariable(key, current + increment);
    });

    yarnProject.commands.addCommand2('sub', (String varName, num increment) {
      log(varName);
      final key = varName;
      final current = yarnProject.variables.getNumericValue(key);
      yarnProject.variables.setVariable(key, current - increment);
    });

    // Redirigir a la pantalla de agendar donación
    yarnProject.commands.addCommand0(('goto_module'), () {

          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          Navigator.push(
            appContext,
            MaterialPageRoute(builder: (context) => const ScheduleScreen()),
          );
    });


    yarnProject.commands.addCommand0('export_image', () async {
      final keyRepaint = GlobalKey();
      // Mostramos un Dialog con la tarjeta para que se renderice
      showDialog(
        context: appContext,
        builder: (_) => Center(
          child: ResumenDonante(
            avatar: yarnProject.variables.getStringValue(r'$avatar'),
            confianza: yarnProject.variables.getNumericValue(r'$confianza').toInt(),
            miedo: yarnProject.variables.getNumericValue(r'$miedo').toInt(),
            viaje: yarnProject.variables.getBooleanValue(r'$viaje'),
            medicacion: yarnProject.variables.getBooleanValue(r'$medicacion'),
            keyRepaint: keyRepaint,
          ),
        ),
      );

      // Esperamos que el frame se dibuje
      await Future.delayed(const Duration(milliseconds: 100));

      final imageBytes = await exportWidgetToImage(keyRepaint);
      // Aquí puedes guardar o compartir
      // Por ejemplo usando share_plus:
      // await Share.shareXFiles([XFile.fromData(imageBytes!, mimeType: 'image/png')]);

      // Cerramos el diálogo
      Navigator.of(appContext).pop();

      // Mostramos popup de finalización
      showDialog(
        context: appContext,
        builder: (_) => AlertDialog(
          title: const Text("¡Terminaste el juego!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(appContext).pop(); // cierra popup
                Navigator.of(appContext).pop(); // vuelve a página principal
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
    );
  

    yarnProject
      ..parse(startDialogueData)
      ..parse(centroData)
      ..parse(finalData);

    dialogueRunner = DialogueRunner(
      yarnProject: yarnProject,
      dialogueViews: [projectViewComponent,ttsDialogueView],
    );


    dialogueRunner.startDialogue('inicio').then((_) {
      if (!avatarPlaced) {
        projectViewComponent.setAvatar(protagonistSprite);
      }
    });
      
    add(projectViewComponent);
    
    return super.onLoad();
  }
}