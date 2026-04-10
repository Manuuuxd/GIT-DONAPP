import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'blood_game.dart';
import 'compatibility.dart';

final _white = BasicPalette.white.paint();
final _black = BasicPalette.black.paint();

class BloodSprites {
  static final Map<String, Sprite> cache = {};

  static Future<void> loadAll() async {
    final bloodTypes = [
      'Aplus', 'Aminus',
      'Bplus', 'Bminus',
      'ABplus', 'ABminus',
      'Oplus', 'Ominus',
    ];

    for (final type in bloodTypes) {
      cache[type] = await Sprite.load(
        'TransfusionJuego/BolsasSangre/blood_$type.png',
      );
      cache['pedido_$type'] = await Sprite.load(
        'TransfusionJuego/PedidoSangre/$type.png',
      );
    }
    cache['thankyou'] ??= await Sprite.load('TransfusionJuego/ThankyouPulgar.png');
    cache['thankyouMessage'] ??= await Sprite.load('TransfusionJuego/thankyou.png');


  }

  static Sprite get(String blood) {
    final key = blood
        .replaceAll('+', 'plus')
        .replaceAll('-', 'minus');
    return cache[key]!;
  }

  static Sprite getpedido(String blood) {
    final key = 'pedido_'+blood
        .replaceAll('+', 'plus')
        .replaceAll('-', 'minus');
    return cache[key]!;
  }

  static Sprite getThankYou() {
    return cache['thankyou']!;
  }

}

class DonorChip extends PositionComponent
    with DragCallbacks, HasGameRef<BloodGame> {
  DonorChip({required this.blood, required Vector2 position}) {
    this.position = position;
    size = Vector2.all(80); // smaller and consistent
    anchor = Anchor.topLeft;
  }

  final String blood;
  Vector2? _dragStartLocal;

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Render the blood sprite proportionally inside
    final sprite = BloodSprites.get(blood);
    sprite.render(
      canvas,
      size: Vector2(size.x * 0.9, size.y * 0.9), // leave padding
      position: Vector2(size.x * 0.05, size.y * 0.05),
    );

    // Border aligned with local rect

  }

  @override
  void onDragStart(DragStartEvent event) {
    _dragStartLocal = event.localPosition;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragStartLocal == null) return;
    position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    final slots = gameRef.world.children.whereType<NeedSlot>();
    final donorRect = toRect();

    for (final s in slots) {
      if (donorRect.overlaps(s.toRect())) {
        final at = position + size / 2;
        gameRef.onDropAttempt(donor: blood, target: s.blood, at: at);

        if (BloodCompatibility.canDonate(blood, s.blood)) {
          removeFromParent();

          final current = Map<String, int>.from(gameRef.resources.value);
          if (current.containsKey(blood) && current[blood]! > 0) {
            current[blood] = current[blood]! - 1;
            gameRef.resources.value = current;
          }
          gameRef.addHospitalRequest(s.blood);
          s.complete();
          Future.delayed(const Duration(seconds: 2), () {
            gameRef.addHospitalRequest(s.blood);
          });
          return;
        }

      }
    }
  }
}

class NeedSlot extends SpriteComponent with HasGameRef<BloodGame> {
  final String blood;
  final VoidCallback? onResolved; // <-- class property
  final bool restored;
  bool _completed = false;

  NeedSlot({
    required this.blood,
    required Rect rect,
    this.onResolved,
    this.restored = false,// <-- accept it in constructor
  }) : super(
    size: Vector2(120, 100),
    position: restored
        ? Vector2(rect.left, rect.top)
        : Vector2(rect.left + 300, rect.top),
    anchor: Anchor.topLeft,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = BloodSprites.getpedido(blood);
    // Slide in
    if (!restored) {
      add(
        MoveEffect.to(
          Vector2(position.x - 230, position.y),
          EffectController(duration: 1.2, curve: Curves.easeOutBack),
        ),
      );
    }
    // Gentle idle floating
    add(
      MoveEffect.by(
        Vector2(0, 8),
        EffectController(
          duration: 2.5,
          alternate: true,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Soft breathing opacity
    add(
      OpacityEffect.by(
        -0.3,
        EffectController(
          duration: 1.6,
          alternate: true,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }


  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // Render sprite with padding
    final sprite = BloodSprites.getpedido(blood);
    sprite.render(
      canvas,
      size: Vector2(size.x * 0.9, size.y + 20),
      position: Vector2(size.x * 0.05, size.y * 0.05),
    );
  }

  bool get completed => _completed;
  void complete({bool skipAnimation = false}) {
    if (_completed) return;
    _completed = true;

    onResolved?.call();

    if (skipAnimation) {
      // Just swap sprite to thank-you immediately
      sprite = BloodSprites.getThankYou();
      return;
    }

    final thankYou = SpriteComponent(
      sprite: BloodSprites.getThankYou(),
      size: size,
      position: position.clone(),
      anchor: anchor,
    );
    gameRef.world.add(thankYou);

    add(
      MoveEffect.to(
        Vector2(position.x + 400, position.y),
        EffectController(duration: 1, curve: Curves.easeIn),
        onComplete: () {
          removeFromParent();
          thankYou.add(
            OpacityEffect.to(
              0,
              EffectController(duration: 1, curve: Curves.easeOut),
              onComplete: () => thankYou.removeFromParent(),
            ),
          );
        },
      ),
    );
  }
}

class ReceptorZone extends PositionComponent with HasGameRef<BloodGame> {
  final Rect area;

  ReceptorZone({required this.area});

  @override
  void render(Canvas canvas) {
    final rect = area.deflate(4);

    // Glassy translucent panel with subtle tint
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x55FFFFFF), // soft white transparency
          Color(0x22FFCDD2), // faint red tint
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      bgPaint,
    );

    // Glossy border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..shader = const LinearGradient(
        colors: [Colors.white70, Colors.redAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(24)),
      borderPaint,
    );

    // Add a faint shadow for depth
    canvas.drawShadow(Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24))), Colors.black54, 4, false);

    // Label
    final tp = TextPainter(
      text: const TextSpan(
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.left + 12, rect.top - 28));
  }

}