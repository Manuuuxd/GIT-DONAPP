import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:donapp_android/CONFIG/api_config.dart';

class AmistadesScreen extends StatefulWidget {
  const AmistadesScreen({super.key});

  @override
  State<AmistadesScreen> createState() => _AmistadesScreenState();
}

class _AmistadesScreenState extends State<AmistadesScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isSending = false;
  bool _isLoadingRequests = false;
  List<dynamic> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingRequests();
  }

  Future<void> _fetchPendingRequests() async {
    setState(() => _isLoadingRequests = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.get(
      Uri.parse(ApiConfig.endpoint("api/users/friends/pending/")),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      setState(() {
        _pendingRequests = jsonDecode(response.body);
      });
    }

    setState(() => _isLoadingRequests = false);
  }

  Future<void> _sendFriendRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (_usernameController.text.isEmpty) return;

    setState(() => _isSending = true);

    
    // ✅ Debug: mostrar URL y body antes de enviar
    print("URL: ${ApiConfig.endpoint("api/users/friends/send/")}");
    print("Body: ${jsonEncode({'username': _usernameController.text})}");

    final response = await http.post(
      Uri.parse(ApiConfig.endpoint("api/users/friends/send/")),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'username': _usernameController.text}),
    );

    setState(() => _isSending = false);

    // --- DEPURACIÓN ---
    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');
    // -------------------

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud enviada')),
      );
      _usernameController.clear();
    } else if (response.headers['content-type'] != null &&
        response.headers['content-type']!.contains('application/json')) {
      // si responde JSON pero con error
      final data = jsonDecode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar: ${data['detail'] ?? response.body}')),
      );
    } else {
      // responde HTML u otro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error al enviar (no JSON): Status ${response.statusCode}\nRevisa backend')),
      );
    }
  }

  Future<void> _respondFriendRequest(int requestId, String action) async {
    // action: 'accept' o 'reject'
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    final response = await http.post(
      Uri.parse(ApiConfig.endpoint("api/users/friends/respond/$requestId/")),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'action': action}),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitud ${action == 'accept' ? 'aceptada' : 'rechazada'}')),
      );
      _fetchPendingRequests(); // refresca la lista
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Amigos")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Enviar solicitud de amistad:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: "Nombre de usuario",
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isSending ? null : _sendFriendRequest,
                  child: _isSending
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Enviar"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Solicitudes pendientes:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _isLoadingRequests
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingRequests.isEmpty
                      ? const Center(child: Text("No tienes solicitudes"))
                      : ListView.builder(
                          itemCount: _pendingRequests.length,
                          itemBuilder: (context, index) {
                            final req = _pendingRequests[index];
                            return Card(
                              child: ListTile(
                                title: Text(req['sender_username']),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _respondFriendRequest(req['id'], 'accept'),
                                      child: const Text("Aceptar"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey),
                                      onPressed: () => _respondFriendRequest(req['id'], 'reject'),
                                      child: const Text("Rechazar"),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
