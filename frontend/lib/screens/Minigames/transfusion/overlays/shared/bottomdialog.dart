import 'package:flutter/material.dart';

// --- Shared bottom-sheet wrapper ---
class BottomDialog extends StatelessWidget {
  final Widget child;
  final VoidCallback? onDismiss;
  const BottomDialog({required this.child, this.onDismiss, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        color: Colors.black45,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
