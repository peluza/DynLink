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
    await prefs.reload(); // Force reload from disk to catch background updates
    final jsonString = prefs.getString(_storageKey);
    print(
      "DEBUG: loadConfigs raw string: ${jsonString?.substring(0, jsonString.length > 50 ? 50 : jsonString.length)}...",
    );
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _configs = jsonList.map((e) => DDNSConfig.fromJson(e)).toList();
      print("DEBUG: loadConfigs parsed ${_configs.length} configs.");
      for (var c in _configs) {
        print("DEBUG: Config ${c.domain} logs: ${c.logs.length}");
      }
      notifyListeners();
    } else {
      print("DEBUG: loadConfigs found NULL storage");
    }
  }

  Future<void> addConfig(DDNSConfig config) async {
    print("DEBUG: addConfig adding ${config.domain}");
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
    print("DEBUG: _saveToStorage called with ${_configs.length} configs");
    final prefs = await SharedPreferences.getInstance();
    // Note: No reload here to avoid overwriting RAM state with old Disk state
    // But be careful not to overwrite background logs if we haven't loaded them recently!
    // Ideally we should merge? For now, relying on frequent loadConfigs() is safer.
    final jsonList = _configs.map((c) => c.toJson()).toList();
    final jsonStr = jsonEncode(jsonList);
    print("DEBUG: _saveToStorage writing ${jsonStr.length} bytes");
    await prefs.setString(_storageKey, jsonStr);
  }

  // Static helper for background service to read without Provider context
  static Future<List<DDNSConfig>> getConfigsStatic() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Crucial for background service to see latest config
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
    print("DEBUG: updateStatusStatic start for $id");
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload(); // Ensure we are appending to the LATEST logs
    final jsonString = prefs.getString(_storageKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final List<DDNSConfig> list = jsonList
          .map((e) => DDNSConfig.fromJson(e))
          .toList();

      final index = list.indexWhere((c) => c.id == id);
      if (index != -1) {
        print("DEBUG: Found config. Prev logs: ${list[index].logs.length}");
        // Create new log entry
        final newLog = LogEntry(
          time: time,
          status: status.contains('Success') ? 'Success' : 'Error',
          message: status,
        );

        // Append log and enforce limit (Circular Buffer)
        final currentLogs = List<LogEntry>.from(list[index].logs);
        currentLogs.insert(0, newLog);

        if (currentLogs.length > 50) {
          currentLogs.removeLast(); // Remove oldest
        }

        list[index] = list[index].copyWith(
          lastStatus: status,
          lastUpdate: time,
          logs: currentLogs,
        );

        print("DEBUG: New logs count: ${currentLogs.length}. Saving...");

        final newJsonList = list.map((c) => c.toJson()).toList();
        final encodedJson = jsonEncode(newJsonList);
        final success = await prefs.setString(_storageKey, encodedJson);
        print("DEBUG: setString returned: $success");

        // Force commit to disk - crucial for background persistence
        await prefs.reload();
        print("DEBUG: Reload after save completed");
      } else {
        print("DEBUG: Config ID not found in static update");
      }
    } else {
      print("DEBUG: Storage null in static update");
    }
  }

  // Instance method for foreground updates (e.g. "Test Now" button)
  Future<void> logUpdate(String id, String status, DateTime time) async {
    await updateStatusStatic(id, status, time);
    await loadConfigs(); // Reload to refresh UI
  }
}
