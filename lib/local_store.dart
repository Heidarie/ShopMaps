import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class LocalStore {
  static const String _storageKey = 'shopping_guide_data_v1';

  Future<AppData> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return AppData.empty();
    }

    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) {
        return AppData.fromJson(Map<String, dynamic>.from(parsed));
      }
    } catch (_) {
      return AppData.empty();
    }

    return AppData.empty();
  }

  Future<void> save(AppData data) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(data.toJson());
    await preferences.setString(_storageKey, raw);
  }
}
