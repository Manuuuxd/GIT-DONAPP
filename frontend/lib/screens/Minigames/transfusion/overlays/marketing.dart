import 'package:donapp_android/screens/Minigames/transfusion/overlays/shared/positivemessage.dart';
import 'package:flutter/material.dart';
import '../blood_game.dart';
import 'shared/panelscaffold.dart';

class MarketingOverlay extends StatelessWidget {
  final BloodGame game;
  const MarketingOverlay(this.game, {super.key});



  void _showResultMessage(BuildContext context, bool success, String action) {
    final color = success ? Colors.greenAccent : Colors.redAccent;
    final message = success ? "$action Exito!" : "$action Fallida!";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color.withOpacity(0.85),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return PanelScaffold(
      backgroundAsset: 'assets/images/marketing.png',
      foreground: const [
        Positioned(
          left: 0, right: 0, bottom: 0, height: 140,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
      child: Stack(
        children: [
          /// Title + upgrade button at the top
          Positioned(
            left: 16, right: 16, top: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Marketing',
                  style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("¡Este sistema aún no está disponible!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent.withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.upgrade, size: 18),
                  label: const Text("Mejoras"),
                ),
              ],
            ),
          ),

          /// Main control section in the center
          Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24), // más espacio
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white54, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    /// Blood type selector
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tipo de sangre: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18, // más grande
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                          ),
                        ),
                        const SizedBox(width: 12), // un poco más de espacio
                        DropdownButton<String>(
                          value: game.selectedBloodType,
                          dropdownColor: Colors.black87,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18, // más grande
                            fontWeight: FontWeight.w600,
                          ),
                          underline: Container(
                            height: 2,
                            color: Colors.white70,
                          ),
                          items: const [
                            'A+', 'O+', 'B+', 'AB+', 'A-', 'O-', 'B-', 'AB-'
                          ].map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 18, // tamaño del item
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )).toList(),
                          onChanged: (v) {
                            if (v != null) game.selectedBloodType = v;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// Action buttons with probabilities underneath
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => game.performCall(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Llamar'),
                            ),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: 0.8,
                              child: Text(
                                "Probabilidad de éxito: ${(game.callSuccessProb * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => game.performCall(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.tealAccent.shade700,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Campaña'),
                            ),
                            const SizedBox(height: 6),
                            Opacity(
                              opacity: 0.8,
                              child: Text(
                                "Probabilidad de éxito: ${(game.campaignSuccessProb * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// People available display
                    ValueListenableBuilder<int>(
                      valueListenable: game.peopleNotifier,
                      builder: (context, available, _) {
                        return Text(
                          "Personas Disponibles: $available",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        "Personas Disponibles: ${game.availablePeople}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                        ),
                      ),
                    ),
                    // Add this inside your Stack in MarketingOverlay, so it appears at the bottom
                    PositiveMessageOverlay(game),
                  ],
                ),
              ),
            ),

        ],


      ),
    );
  }
}
