import 'package:flutter/material.dart';
import '../../blood_game.dart';

class PositiveMessageOverlay extends StatelessWidget {
  final BloodGame game;
  const PositiveMessageOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: game.positiveMessage,
      builder: (context, msg, _) {
        if (msg.isEmpty) return const SizedBox.shrink();
        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black87.withOpacity(0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
