// --- Hint Overlay ---
import 'package:flutter/material.dart';
import '../blood_game.dart';
import 'shared/bottomdialog.dart';

final hintText = ValueNotifier<String>('');
class HintOverlay extends StatelessWidget {
  final BloodGame game;
  const HintOverlay(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    return BottomDialog(
      onDismiss: () => game.overlays.remove('Hint'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('💡 Pista',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: hintText,
            builder: (_, v, __) => Text(v, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          const Text('Se aplicó una penalización de −5% al puntaje del nivel.'),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => game.overlays.remove('Hint'),
            child: const Text('Continuar'),
          )
        ],
      ),
    );
  }
}
