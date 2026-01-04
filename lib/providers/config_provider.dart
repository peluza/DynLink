import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ddns_config.dart';

class ConfigProvider extends ChangeNotifier {
  static const String _storageKey = 'saved_configs_v2';
  List<DDNSConfig> _configs = [];

  List<DDNSConfig> get configs => _configs;

  Future<void> loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _configs = jsonList.map((e) => DDNSConfig.fromJson(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addConfig(DDNSConfig config) async {
    _configs.add(config);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> updateConfig(DDNSConfig updatedConfig) async {
    final index = _configs.indexWhere((c) => c.id == updatedConfig.id);
    if (index != -1) {
      _configs[index] = updatedConfig;
      await _saveToStorage();
      notifyListeners();
    }
  }

  Future<void> removeConfig(String id) async {
    _configs.removeWhere((c) => c.id == id);
    await _saveToStorage();
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _configs.map((c) => c.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  // Static helper for background service to read without Provider context
  static Future<List<DDNSConfig>> getConfigsStatic() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((e) => DDNSConfig.fromJson(e)).toList();
    }
    return [];
  }

  // Static helper to update status from background
  static Future<void> updateStatusStatic(
    String id,
    String status,
    DateTime time,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<DDNSConfig> list = jsonList
          .map((e) => DDNSConfig.fromJson(e))
          .toList();

      final index = list.indexWhere((c) => c.id == id);
      if (index != -1) {
        // Create new log entry
        final newLog = LogEntry(
          time: time,
          status: status.contains('Success') ? 'Success' : 'Error',
          message: status,
        );

        // Append log and enforce limit (Circular Buffer)
        final currentLogs = List<LogEntry>.from(list[index].logs);
        currentLogs.insert(0, newLog); // Add easiest to front for UI? Or back?
        // Typically UI wants newest first. Let's insert at 0.

        if (currentLogs.length > 50) {
          currentLogs.removeLast(); // Remove oldest
        }

        list[index] = list[index].copyWith(
          lastStatus: status,
          lastUpdate: time,
          logs: currentLogs,
        );

        final newJsonList = list.map((c) => c.toJson()).toList();
        await prefs.setString(_storageKey, jsonEncode(newJsonList));
      }
    }
  }

  // Instance method for foreground updates (e.g. "Test Now" button)
  Future<void> logUpdate(String id, String status, DateTime time) async {
    await updateStatusStatic(id, status, time);
    await loadConfigs(); // Reload to refresh UI
  }
}
