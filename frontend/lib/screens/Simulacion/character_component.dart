import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';

enum CharacterDirection { left, right }
enum CharacterStartLocation { left, right }

class CharacterComponent extends SpriteComponent with HasGameRef {
  List<Sprite> sprites;

  double leftBorder = 0.0;
  late double rightBorder;
  final CharacterStartLocation startLocation;
  late CharacterDirection direction;
  bool move = false;
  late Timer interval;
  final randomNumberGenerator = Random();

  CharacterComponent({required this.sprites, required this.startLocation})
      : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() {
    // Escalamos el tamaño del personaje relativo a la pantalla del celular
    size = Vector2(gameRef.size.x * 0.15, gameRef.size.y); // 15% ancho, 20% alto

    // Inicializamos el sprite
    sprite = sprites[0];

    // Configuramos posición inicial y límites según lado de inicio
    if (startLocation == CharacterStartLocation.left) {
      position = Vector2(size.x / 2, gameRef.size.y * 0.8); // 80% altura para estar "en el suelo"
      leftBorder = 0.0;
      rightBorder = gameRef.size.x / 3;
      direction = CharacterDirection.left;
    } else {
      rightBorder = gameRef.size.x - size.x / 2;
      leftBorder = gameRef.size.x * 0.6;
      position = Vector2(gameRef.size.x - size.x / 2, gameRef.size.y * 0.8);
      direction = CharacterDirection.right;
    }

    // Configuramos el intervalo de movimiento
    double moveIntervalTime = randomNumberGenerator.nextDouble() * 3 + 2; // 2 a 5 segundos
    interval = Timer(moveIntervalTime, onTick: () {
      move = !move;
    }, repeat: true);

    return super.onLoad();
  }

  @override
  void update(double dt) {
    // Ajustamos la velocidad relativa al ancho de la pantalla
    double moveSpeed = gameRef.size.x * 0.1; // 10% ancho por segundo

    switch (direction) {
      case CharacterDirection.left:
        if (x - size.x / 2 > leftBorder) {
          if (move) x -= moveSpeed * dt;
        } else {
          direction = CharacterDirection.right;
          move = false;
          if (randomNumberGenerator.nextBool()) {
            sprite = sprites[randomNumberGenerator.nextInt(sprites.length)];
          }
          if (randomNumberGenerator.nextBool()) flipHorizontallyAroundCenter();
        }
        break;

      case CharacterDirection.right:
        if (x < rightBorder) {
          if (move) x += moveSpeed * dt;
        } else {
          direction = CharacterDirection.left;
          move = false;
          if (randomNumberGenerator.nextBool()) flipHorizontallyAroundCenter();
          if (randomNumberGenerator.nextBool()) {
            sprite = sprites[randomNumberGenerator.nextInt(sprites.length)];
          }
        }
        break;
    }

    interval.update(dt);
    super.update(dt);
  }
}