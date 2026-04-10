import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

import 'character_component.dart';
import 'sim.dart';

class ProjectViewComponent extends PositionComponent
    with DialogueView, HasGameReference<JennyGame> {
  late final TextBoxComponent mainDialogueTextComponent;
  late TextPaint dialoguePaint;
  final background = SpriteComponent();
  late CharacterComponent girl;
  late CharacterComponent boy;
  late final ButtonComponent forwardButtonComponent;

  // to control flow with button presses
  Completer<void> _forwardCompleter = Completer();
  Completer<int> _choiceCompleter = Completer<int>();

  List<ButtonComponent> optionsList = [];

  bool _avatarSet = false;
  late Vector2 _originalDialoguePosition;

  void _initBoy() {
    boy = CharacterComponent(
      sprites: [], // empieza vacío
      startLocation: CharacterStartLocation.right,
    )
      ..size = Vector2(400, 800)
      ..position = Vector2(game.size.x * .7, 0); // posición fija derecha
  }

void setAvatar(Sprite chosenSprite) {
  if (!_avatarSet) {
    // Inicializa el protagonista si no estaba
    boy.sprites = [chosenSprite];
    boy.sprite = chosenSprite;
    boy.size = Vector2(game.size.x * 0.25, game.size.y * 0.6);
    boy.position = Vector2(game.size.x * 0.7, 0);

    add(boy); // Esto funciona porque ProjectViewComponent ya está montado
    _avatarSet = true;
  } else {
    // Si ya estaba agregado, solo actualizamos el sprite
    boy.sprite = chosenSprite;
  }

  debugPrint("✅ Protagonista actualizado en pantalla");
}
  @override
  FutureOr<void> onLoad() {
    background
      ..sprite = game.seleccionSprite
      ..size = game.size;
    girl = CharacterComponent(
        sprites: [game.girlSprite],
        startLocation: CharacterStartLocation.left)
      ..size = Vector2(game.size.x * 0.20, game.size.y / 3)
      ..position = Vector2(game.size.x / 3, game.size.y * -0.7);

    // ensures it only happens once

    _initBoy();


    dialoguePaint = TextPaint(
      style: TextStyle(
        backgroundColor: const Color.fromARGB(180, 85, 84, 84),
        fontSize: game.size.x * 0.035, // 🔑 Escala con el ancho
      ),
    );

    forwardButtonComponent = ButtonComponent(
      position: Vector2(game.size.x * 0.8, game.size.y * 0.9),
      size: Vector2(game.size.x * 0.15, game.size.y * 0.07),
      button: TextComponent(
        text: 'Siguiente',
        textRenderer: dialoguePaint,
        anchor: Anchor.center,
      ),
      onPressed: () {
        if (!_forwardCompleter.isCompleted) {
          _forwardCompleter.complete();
        }
      },
    );
    mainDialogueTextComponent = TextBoxComponent(
      text: 'Apreta siguiente para seguir la historia...',
      position: Vector2(game.size.x * 0.05, game.size.y * 0.6),
      boxConfig: TextBoxConfig(maxWidth: game.size.x * 0.9),
      textRenderer: dialoguePaint,
      priority: 5,
    );

    _originalDialoguePosition = mainDialogueTextComponent.position.clone();

    addAll([
      background,
      forwardButtonComponent,
      mainDialogueTextComponent
    ]);
    return super.onLoad();
  }

  @override
  FutureOr<bool> onLineStart(DialogueLine line) async {
    _forwardCompleter = Completer();
    await _advance(line);
    return super.onLineStart(line);
  }

  @override
  FutureOr<int?> onChoiceStart(DialogueChoice choice) async {
    _choiceCompleter = Completer<int>();
    forwardButtonComponent.removeFromParent();
    mainDialogueTextComponent.text = 'Elige tu opción';
    mainDialogueTextComponent.position = Vector2(
      mainDialogueTextComponent.position.x,
      game.size.y * 0.85,
    );
    for (int i = 0; i < choice.options.length; i++) {
      optionsList.add(
        ButtonComponent(
            position: Vector2(game.size.x*0.1, i * 70 + 100),
            button: TextComponent(
              text: 'Elegiste ${i + 1}: ${choice.options[i].text}',
              textRenderer: dialoguePaint,
            ),
            onPressed: () {
              if (!_choiceCompleter.isCompleted) {
                _choiceCompleter.complete(i);
              }
            }),
      );
    }

    addAll(optionsList);
    await _getChoice(choice);
    return _choiceCompleter.future;
  }

  @override
  FutureOr<void> onChoiceFinish(DialogueOption option) {
    mainDialogueTextComponent.text = 'Tu decision es ${option.text}';
    mainDialogueTextComponent.position = _originalDialoguePosition.clone(); // restore position

    removeAll(optionsList);
    optionsList = [];
    add(forwardButtonComponent);
  }

  @override
  FutureOr<void> onNodeStart(Node node) {
    switch (node.title) {
      case 'camino_al_centro':
        background.sprite = game.fueraCentroSprite;
        break;
      case 'registro':
        background.sprite = game.registroSprite;
        break;
      case 'entrevista_medica':
        background.sprite = game.entrevista_medicaSprite;
        break;
      case 'zona_espera':
        background.sprite = game.zona_esperaSprite;
        break;
      case 'extraccion':
        background.sprite = game.extraccionSprite;
        break;
      case 'recuperacion':
        background.sprite = game.recuperacionSprite;
        break;
      case 'epilogo':
        background.sprite = game.seleccionSprite;
        break;
    }
    return super.onNodeStart(node);
  }

  Future<void> _getChoice(DialogueChoice choice) async {
    return _forwardCompleter.future;
  }

  Future<void> _advance(DialogueLine line) async {
    final avatarValue = game.yarnProject.variables.getStringValue(r'$avatar');
    debugPrint("🎭 Valor de \$avatar desde Yarn: $avatarValue");

    var dialogueLineText;

    if (line.character != null && line.character!.name.isNotEmpty) {
      // If there's a character, prefix with avatar value
      dialogueLineText = "$avatarValue: ${line.text}";
    } else {
      // If it's narration or system text, just show the text
      dialogueLineText = line.text;
    }

    mainDialogueTextComponent.text = dialogueLineText;
    debugPrint('debug: $dialogueLineText');
    return _forwardCompleter.future;
  }
}