import 'package:flutter/material.dart';
import '../blood_game.dart';
import 'shared/bottomdialog.dart';

final incorrectMessage = ValueNotifier<String>('');

class IncorrectOverlay extends StatelessWidget {
  final BloodGame game;
  const IncorrectOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // translucent dark background
        Positioned.fill(
          child: Container(color: Colors.black54),
        ),
        Center(
          child: Card(
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '❌ Incorrecto',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<String>(
                    valueListenable: incorrectMessage,
                    builder: (_, v, __) =>
                        Text(v, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => game.overlays.remove('Incorrect'),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}