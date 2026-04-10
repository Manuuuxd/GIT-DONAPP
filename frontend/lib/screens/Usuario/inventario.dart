import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:donapp_android/CONFIG/api_config.dart';
import 'package:donapp_android/screens/Usuario/items_model.dart';
import 'package:donapp_android/screens/Usuario/handle_item.dart';

class UserItem {
  final int id;
  final Item item;
  final int cantidad;

  UserItem({required this.id, required this.item, required this.cantidad});

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'],
      item: Item.fromJson(json['item']),
      cantidad: json['cantidad'],
    );
  }
}

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({Key? key}) : super(key: key);

  @override
  _InventarioScreenState createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late Future<List<UserItem>> _futureInventario;

  @override
  void initState() {
    super.initState();
    _futureInventario = fetchUserInventory();
  }

  Future<List<UserItem>> fetchUserInventory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final url = ApiConfig.endpoint('api/logros/user-items/');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => UserItem.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar inventario');
    }
  }

  Future<List<Item>> fetchAllItemsCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken') ?? '';
    final url = ApiConfig.endpoint('api/logros/items/');

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Item.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar catálogo de ítems');
    }
  }

  void showItemsCatalog(BuildContext context) async {
    List<Item>? items;
    try {
      items = await fetchAllItemsCatalog();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar catálogo: $e')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: items?.length ?? 0,
          itemBuilder: (context, index) {
            final item = items![index];
            return ListTile(
              leading: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Image.asset(
                  'assets/images/items/${item.slug}.png',
                  width: 40,
                  height: 40,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.image_not_supported_outlined, color: Colors.red);
                  },
                ),
              ),
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.description),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ver catálogo de ítems',
            onPressed: () => showItemsCatalog(context),
          ),
        ],
      ),
      body: FutureBuilder<List<UserItem>>(
        future: _futureInventario,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes ítems en tu inventario.'));
          }
          final inventario = snapshot.data!;
          return ListView.builder(
            itemCount: inventario.length,
            itemBuilder: (context, index) {
              final userItem = inventario[index];
              return ListTile(
                leading: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    'assets/images/items/${userItem.item.slug}.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported_outlined, color: Colors.red);
                    },
                  ),
                ),
                title: Text(userItem.item.name),
                subtitle: Text(userItem.item.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x${userItem.cantidad}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    if (userItem.item.canjeable && userItem.cantidad > 0)
                      IconButton(
                        tooltip: 'Canjear ítem',
                        icon: const Icon(Icons.redeem_outlined, color: Colors.green),
                        onPressed: () async {
                          try {
                            final respuesta = await canjearItem(userItem.item.slug, cantidad: 1);
                            if (respuesta['status'] == 'item_canjeado') {
                              showItemDialog(
                                context,
                                title: '¡Ítem canjeado!',
                                message: 'Has canjeado: ${userItem.item.name}, se han agregado ${userItem.item.value} puntos de experiencia.',
                                imageAssetPath: 'assets/images/items/${userItem.item.slug}.png',
                              );
                              setState(() {
                                _futureInventario = fetchUserInventory();
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('No se pudo canjear: ${respuesta['detalle'] ?? 'Error'}')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al canjear: $e')),
                            );
                          }
                        },
                      ),
                  ],
                ),
                // El onTap se puede dejar vacío, ahora todo es por el botón de canjeo
              );

            },
          );
        },
      ),
    );
  }
}