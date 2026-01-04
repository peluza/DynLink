import 'package:flutter/foundation.dart';
import 'ddns_providers/ddns_provider.dart';
import 'ddns_providers/duckdns_provider.dart';

class DDNSService extends ChangeNotifier {
  // Strategy: Default to DuckDNS for now
  DDNSProvider _provider = DuckDNSProvider();

  String _lastStatus = 'Idle';
  String? _currentIP;

  String get lastStatus => _lastStatus;
  String? get currentIP => _currentIP;

  /// Updates the provider strategy (for future multi-provider support)
  void setProvider(DDNSProvider provider) {
    _provider = provider;
    notifyListeners();
  }

  /// Triggers an immediate update.
  Future<void> performUpdate(String domain, String token) async {
    _lastStatus = 'Updating...';
    notifyListeners();

    try {
      final result = await _provider.updateIP(domain, token);

      // Also fetch current public IP for verification
      _currentIP = await _provider.getExternalIP();

      _lastStatus = result;
    } catch (e) {
      _lastStatus = 'Error: $e';
    } finally {
      notifyListeners();
    }
  }

  // Static method for background execution where we don't have the Provider context
  static Future<String> backgroundUpdate(String domain, String token) async {
    // In background, we currently assume DuckDNS or load pref
    // For MVP we default to DuckDNSProvider
    final provider = DuckDNSProvider();
    return await provider.updateIP(domain, token);
  }
}
