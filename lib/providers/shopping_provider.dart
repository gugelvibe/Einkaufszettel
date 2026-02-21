import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_models.dart';

class ShoppingProvider with ChangeNotifier {
  List<ShoppingList> _lists = [];
  int _currentListIndex = 0;
  bool _isInputDisabled = false;
  List<String> _itemHistory = [];
  final _uuid = const Uuid();

  late Future<void> initialized;

  ShoppingProvider() {
    initialized = _loadFromPrefs();
  }

  List<ShoppingList> get lists => _lists;
  ShoppingList? get currentList =>
      _lists.isNotEmpty ? _lists[_currentListIndex] : null;

  bool get isInputDisabled => _isInputDisabled;
  List<String> get itemHistory => _itemHistory;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? listsJson = prefs.getString('shopping_lists');
    if (listsJson != null) {
      final List<dynamic> decoded = jsonDecode(listsJson);
      _lists = decoded.map((e) => ShoppingList.fromJson(e)).toList();
    } else {
      // Create a default list if none exists
      _lists = [ShoppingList(id: _uuid.v4(), name: 'Supermarkt', items: [])];
    }
    _currentListIndex = prefs.getInt('current_list_index') ?? 0;
    if (_currentListIndex >= _lists.length) {
      _currentListIndex = 0;
    }
    _isInputDisabled = prefs.getBool('is_input_disabled') ?? false;
    _itemHistory = prefs.getStringList('item_history') ?? [];
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_lists.map((e) => e.toJson()).toList());
    await prefs.setString('shopping_lists', encoded);
    await prefs.setInt('current_list_index', _currentListIndex);
    await prefs.setBool('is_input_disabled', _isInputDisabled);
    await prefs.setStringList('item_history', _itemHistory);
  }

  void addItem(String name, String quantity) {
    if (currentList == null) return;

    // Check for duplicates
    final normalizedName = name.trim().toLowerCase();
    final alreadyInList = currentList!.items.any(
      (item) => item.name.trim().toLowerCase() == normalizedName,
    );
    if (alreadyInList) return;

    final newItem = ShoppingItem(
      id: _uuid.v4(),
      name: name,
      quantity: quantity,
      position: currentList!.items.length,
    );
    final updatedItems = List<ShoppingItem>.from(currentList!.items)
      ..add(newItem);
    _lists[_currentListIndex] = currentList!.copyWith(items: updatedItems);

    // Add to history if not exists
    if (!_itemHistory.contains(name)) {
      _itemHistory.add(name);
      _itemHistory.sort();
    }

    _saveToPrefs();
    notifyListeners();
  }

  void toggleInputMode() {
    _isInputDisabled = !_isInputDisabled;
    _saveToPrefs();
    notifyListeners();
  }

  void toggleItemDone(String id) {
    if (currentList == null) return;
    final updatedItems = currentList!.items.map((item) {
      if (item.id == id) {
        return item.copyWith(isDone: !item.isDone);
      }
      return item;
    }).toList();
    _lists[_currentListIndex] = currentList!.copyWith(items: updatedItems);
    _saveToPrefs();
    notifyListeners();
  }

  void removeItem(String id) {
    if (currentList == null) return;
    final updatedItems = currentList!.items
        .where((item) => item.id != id)
        .toList();
    _lists[_currentListIndex] = currentList!.copyWith(items: updatedItems);
    _saveToPrefs();
    notifyListeners();
  }

  void reorderItems(int oldIndex, int newIndex) {
    if (currentList == null) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final items = List<ShoppingItem>.from(currentList!.items);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    _lists[_currentListIndex] = currentList!.copyWith(items: items);
    _saveToPrefs();
    notifyListeners();
  }

  void clearList() {
    if (currentList == null) return;
    _lists[_currentListIndex] = currentList!.copyWith(items: []);
    _saveToPrefs();
    notifyListeners();
  }

  void addNewList(String name) {
    final newList = ShoppingList(id: _uuid.v4(), name: name, items: []);
    _lists.add(newList);
    _currentListIndex = _lists.length - 1;
    _saveToPrefs();
    notifyListeners();
  }

  void switchList(int index) {
    if (index >= 0 && index < _lists.length) {
      _currentListIndex = index;
      _saveToPrefs();
      notifyListeners();
    }
  }
}
