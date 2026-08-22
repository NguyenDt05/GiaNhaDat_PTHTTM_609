import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/prediction.dart';

class HistoryRepository {
  static const _storageKey = 'prediction_history_v1';
  static const _maximumEntries = 50;

  Future<List<PredictionResult>> load() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_storageKey);
    if (value == null || value.isEmpty) {
      return [];
    }
    try {
      return (jsonDecode(value) as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PredictionResult.fromStorageJson)
          .toList(growable: false);
    } on FormatException {
      return [];
    }
  }

  Future<void> add(PredictionResult result) async {
    final preferences = await SharedPreferences.getInstance();
    final items = await load();
    final updated = [result, ...items].take(_maximumEntries);
    await preferences.setString(
      _storageKey,
      jsonEncode(updated.map((item) => item.toStorageJson()).toList()),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }
}
