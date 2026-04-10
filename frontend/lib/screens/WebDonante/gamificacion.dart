import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';

class MascotaGame extends FlameGame {
  late SpriteComponent spriteComponent;
  double initialY = 300; // Ajustamos la posición inicial más baja en la pantalla
  double speed = 100;  // Velocidad del movimiento

  @override
  Future<void> onLoad() async {
    // Cargamos el sprite
    final sprite = await loadSprite('blood_drop_character.png');
    spriteComponent = SpriteComponent(
      sprite: sprite,
      size: Vector2(80, 80), // Ajustamos el tamaño para hacerlo más pequeño
      position: Vector2(150, initialY), // Posición inicial más baja
    );
    add(spriteComponent); // Agregar el componente al juego
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Mover el sprite hacia abajo y hacia arriba
    spriteComponent.position.y += speed * dt;

    // Si el sprite llega al final de la pantalla, lo devolvemos hacia arriba
    if (spriteComponent.position.y >= 400) {
      speed = -100; // Cambiar la dirección hacia arriba
    }

    // Si el sprite está en la parte superior, lo movemos hacia abajo
    if (spriteComponent.position.y <= initialY) {
      speed = 100; // Cambiar la dirección hacia abajo
    }
  }
}

class MascotaImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 50, // Colocamos el sprite más abajo
      left: 0,
      right: 0,
      child: GameWidget(game: MascotaGame()), // Usamos el GameWidget para mostrar la animación
    );
  }
}
