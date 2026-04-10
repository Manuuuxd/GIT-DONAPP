
import 'package:flutter/material.dart';
import '../blood_game.dart';
import '../compatibility.dart';
import 'shared/bottomdialog.dart';

class KeyTableOverlay extends StatelessWidget {
  final BloodGame game;
  const KeyTableOverlay(this.game, {super.key});
  @override
  Widget build(BuildContext context) {
    final rows = BloodCompatibility.keyCompatibilityRows();
    return BottomDialog(
      onDismiss: () => game.overlays.remove('KeyTable'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Compatibilidades clave (ABO/Rh)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: 520,
            child: DataTable(
              columns: rows.first.map((h) => DataColumn(label: Text(h))).toList(),
              rows: rows.skip(1).map((r) => DataRow(cells: [
                DataCell(Text(r[0])),
                DataCell(Text(r[1])),
              ])).toList(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => game.overlays.remove('KeyTable'),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }
}