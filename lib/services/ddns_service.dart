import 'package:flutter/foundation.dart';
import '../models/ddns_config.dart';
import 'ddns_providers/ddns_provider.dart';
import 'ddns_providers/duckdns_provider.dart';
import 'ip_service.dart';

class DDNSUpdateResult {
  final String status;
  final String? publicIp;
  final bool success;

  DDNSUpdateResult({required this.status, this.publicIp, this.success = false});
}

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

  Future<void> performUpdate(DDNSConfig config) async {
    _lastStatus = 'Checking IP...';
    notifyListeners();

    try {
      final result = await _smartUpdateLogic(config, _provider);
      _lastStatus = result.status;
      if (result.publicIp != null) {
        _currentIP = result.publicIp;
      }
    } catch (e) {
      _lastStatus = 'Error: $e';
    } finally {
      notifyListeners();
    }
  }

  // Static method for background execution
  static Future<DDNSUpdateResult> backgroundUpdate(DDNSConfig config) async {
    final provider = DuckDNSProvider();
    return await _smartUpdateLogic(config, provider);
  }

  /// Core logic for smart updates
  static Future<DDNSUpdateResult> _smartUpdateLogic(
    DDNSConfig config,
    DDNSProvider provider,
  ) async {
    final ipService = IpService();

    // 1. Get Public IP
    final publicIp = await ipService.getPublicIp();

    // 2. Resolve Domain IP
    final domainIp = await ipService.resolveDomainIp(config.domain);

    // 3. Check 15-day rule
    final daysSinceLastSuccess = config.lastSuccessUpdate != null
        ? DateTime.now().difference(config.lastSuccessUpdate!).inDays
        : 999;

    bool forceUpdate = daysSinceLastSuccess >= 15;

    // 4. Compare
    if (publicIp == domainIp && !forceUpdate) {
      return DDNSUpdateResult(
        status: "Skipped: IP matches domain. No update needed.",
        publicIp: publicIp,
        success: true,
      );
    }

    String statusMsg = "";
    if (forceUpdate && publicIp == domainIp) {
      statusMsg = "(Forced 15-day) ";
    }

    // Perform Update
    final result = await provider.updateIP(config.domain, config.token);

    final fromIp = domainIp ?? "unknown";
    return DDNSUpdateResult(
      status: "$statusMsg$result (Changed from $fromIp to $publicIp)",
      publicIp: publicIp,
      success: true,
    );
  }
}
