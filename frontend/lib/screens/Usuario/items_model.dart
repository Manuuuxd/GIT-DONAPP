// Modelo básico de Item embebido en UserItem
class Item {
  final int id;
  final String name;
  final String slug;
  final int value;
  final String description;
  final String? icon;
  final bool canjeable;

  Item({
    required this.id,
    required this.name,
    required this.slug,
    required this.value,
    required this.description,
    required this.icon,
    required this.canjeable,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      value: json['value'],
      description: json['description'],
      icon: json['icon'],
      canjeable: json['canjeable'] ?? true,
    );
  }
}

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