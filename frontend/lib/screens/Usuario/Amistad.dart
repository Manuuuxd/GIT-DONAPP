import 'package:flutter/material.dart';
import 'package:donapp_android/screens/Usuario/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:donapp_android/CONFIG/api_config.dart';
import 'dart:convert';

class PerfilUsuarioAmigo extends StatefulWidget {
  final int userId;
  const PerfilUsuarioAmigo({super.key, required this.userId});

  @override
  State<PerfilUsuarioAmigo> createState() => _PerfilUsuarioAmigoState();
}

class _PerfilUsuarioAmigoState extends State<PerfilUsuarioAmigo> {
  User? _user;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFriendData();
  }

  Future<void> _fetchFriendData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      setState(() {
        _errorMessage = 'Authentication token not found.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.endpoint("api/users/${widget.userId}/")),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _user = User.fromJson(jsonDecode(response.body));
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load user: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) return Center(child: Text(_errorMessage));
    if (_user == null) return const Center(child: Text("User not found"));

    return Scaffold(
      appBar: AppBar(title: Text(_user!.username)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Puedes reutilizar tus widgets de perfil aquí
            Text("Nombre: ${_user!.username}"),
            Text("Email: ${_user!.email}"),
            // ...otros campos
          ],
        ),
      ),
    );
  }
}