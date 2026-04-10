import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    _checkPolicyAndAuth();
  }

  Future<void> _checkPolicyAndAuth() async {
    final prefs = await SharedPreferences.getInstance();
    //await prefs.clear();

    final hasLaunchedOnce = prefs.getBool('hasLaunchedOnce') ?? false;
    final acceptedPolicy = prefs.getBool('acceptedPolicy') ?? false;
    final authToken = prefs.getString('authToken');

    // 🔹 Step 1: If policy not accepted, show it first (both platforms)


    // 🔹 Step 2: If running on web, skip login entirely (guest access)
    if (kIsWeb) {
      debugPrint('[CheckAuthScreen] Running on Web → skipping login');
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    if (!hasLaunchedOnce || !acceptedPolicy) {
      Navigator.pushReplacementNamed(context, '/politica');
      return;
    }

    // 🔹 Step 3: On mobile, require authentication
    if (authToken != null && authToken.isNotEmpty) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
