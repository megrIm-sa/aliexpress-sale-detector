import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class MemoryManager {
  // Loading and Saving items
  static Future<List<Map<String, dynamic>>> loadItemsFromMemory(items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('items');

    if (itemsJson != null) {
        return items = List<Map<String, dynamic>>.from(json.decode(itemsJson));
    }
    return List<Map<String, dynamic>>.empty();
  }

  static Future<void> saveItemsToMemory(items) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String itemsJson = json.encode(items);
    prefs.setString('items', itemsJson);
  }
}