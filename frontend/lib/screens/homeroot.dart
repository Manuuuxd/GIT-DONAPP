import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:donapp_android/screens/home_screen.dart'; // your current mobile screen
import 'package:donapp_android/screens/home_body_web.dart'; // the new web layout

/// Root home router — automatically decides between mobile and web layout.
class HomeRoot extends StatelessWidget {
  const HomeRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // You can use both kIsWeb and screen width to make it more robust
    final bool isWideScreen = MediaQuery.of(context).size.width > 900;

    if (kIsWeb || isWideScreen) {
      // 🖥️ Web layout
      return const HomeBodyWeb();
    } else {
      // 📱 Mobile layout (your existing one)
      return const HomeScreen();
    }
  }
}
