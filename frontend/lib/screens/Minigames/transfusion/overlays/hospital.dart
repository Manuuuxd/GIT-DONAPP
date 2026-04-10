import 'package:flutter/material.dart';
import '../blood_game.dart';
import 'shared/panelscaffold.dart';
import 'shared/hospital_request.dart';

class HospitalOverlay extends StatelessWidget {
  final BloodGame game;
  const HospitalOverlay(this.game, {super.key});

  @override
  Widget build(BuildContext context) {
    return PanelScaffold(
      backgroundAsset: 'assets/images/centroTransfucionAnimado.png',
      foreground: const [
        // Soft vignette for contrast
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [Colors.transparent, Colors.black26],
                stops: [0.6, 1.0],
              ),
            ),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("transportes de sangre",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white, shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 10),

            // Requests List
            Expanded(
              child: ValueListenableBuilder<List<HospitalRequest>>(
                valueListenable: game.hospitalRequests,
                builder: (context, requests, _) {
                  if (requests.isEmpty) {
                    return const Center(
                      child: Text("No se esta transportando la sangre aún",
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final r = requests[index];
                      return Card(
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text("${r.unitsNeeded}x ${r.bloodType}"),
                          subtitle: TweenAnimationBuilder<double>(
                            duration: r.duration,
                            tween: Tween(begin: 1.0, end: 0.0),
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.red.shade100,
                                color: Colors.redAccent,
                              );
                            },
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => game.fulfillRequest(r),
                            child: const Text("Completandose"),
                          ),
                        ),
                      );

                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 10),
            Text("Mejoras de velocidad para ciertas sangres",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white, shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
            const SizedBox(height: 5),

            ValueListenableBuilder<Map<String, int>>(
              valueListenable: game.resources,
              builder: (context, inventory, _) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: inventory.entries
                      .where((e) => e.value != 0) // only show positive blood amounts
                      .map((e) => Chip(
                    label: Text("${e.key}: ${e.value}"),
                    backgroundColor: Colors.redAccent.shade100,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}