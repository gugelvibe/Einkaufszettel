// import 'package:uuid/uuid.dart';

class ShoppingItem {
  final String id;
  final String name;
  final String quantity;
  final bool isDone;
  final int position;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = '',
    this.isDone = false,
    required this.position,
  });

  ShoppingItem copyWith({
    String? name,
    String? quantity,
    bool? isDone,
    int? position,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isDone': isDone,
      'position': position,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'] ?? '',
      isDone: json['isDone'] ?? false,
      position: json['position'] ?? 0,
    );
  }
}

class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;

  ShoppingList({required this.id, required this.name, required this.items});

  ShoppingList copyWith({String? name, List<ShoppingItem>? items}) {
    return ShoppingList(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'],
      name: json['name'],
      items:
          (json['items'] as List?)
              ?.map((e) => ShoppingItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
