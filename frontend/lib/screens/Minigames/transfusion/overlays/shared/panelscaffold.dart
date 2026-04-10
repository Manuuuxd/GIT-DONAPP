import 'package:flutter/material.dart';

class PanelScaffold extends StatelessWidget {
  final String backgroundAsset;
  final Widget child;
  final List<Widget>? foreground; // optional extra layers (e.g., gradients)

  const PanelScaffold({
    super.key,
    required this.backgroundAsset,
    required this.child,
    this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
            ),
          ),
          // Optional overlays (e.g., gradients)
          if (foreground != null) ...foreground!,
          // Main content
          SafeArea(child: child),
        ],
      ),
    );
  }
}
