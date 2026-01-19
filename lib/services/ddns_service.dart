import 'package:flutter/foundation.dart';
import 'package:ddns_updater/services/ip_service.dart';
import 'package:ddns_updater/services/widget_service.dart';
import '../models/ddns_config.dart';
import 'ddns_providers/ddns_provider.dart';
import 'ddns_providers/duckdns_provider.dart';

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

  Future<void> performUpdate(DDNSConfig config, {IpService? ipService}) async {
    _lastStatus = 'Checking IP...';
    notifyListeners();

    DDNSUpdateResult? result;
    try {
      result = await _smartUpdateLogic(config, _provider, ipService: ipService);
      _lastStatus = result.status;
      if (result.publicIp != null) {
        _currentIP = result.publicIp;
      }
    } catch (e) {
      _lastStatus = 'Error: $e';
    } finally {
      // Update widget with new status
      await WidgetService.updateWidget(
        ip:
            _currentIP ??
            config
                .lastKnownIp, // Use current IP if available, otherwise last known
        domain: config.domain,
        status:
            result?.status ??
            _lastStatus, // Use result status if available, otherwise lastStatus
      );
      notifyListeners();
    }
  }

  // Static method for background execution
  static Future<DDNSUpdateResult> backgroundUpdate(
    DDNSConfig config, {
    IpService? ipService,
    DDNSProvider? provider,
  }) async {
    final ddnsProvider = provider ?? DuckDNSProvider();
    try {
      final result = await _smartUpdateLogic(
        config,
        ddnsProvider,
        ipService: ipService,
      );
      // Update widget with new status
      await WidgetService.updateWidget(
        ip: result.publicIp ?? config.lastKnownIp,
        domain: config.domain,
        status: result.status,
      );
      return result;
    } catch (e) {
      final errorStatus = 'Error: $e';
      // Update widget with error
      await WidgetService.updateWidget(
        ip: config.lastKnownIp, // Keep old IP if available
        domain: config.domain,
        status: 'Error',
      );
      return DDNSUpdateResult(
        status: errorStatus,
        publicIp: null,
        success: false,
      );
    }
  }

  /// Core logic for smart updates
  static Future<DDNSUpdateResult> _smartUpdateLogic(
    DDNSConfig config,
    DDNSProvider provider, {
    IpService? ipService,
  }) async {
    final service = ipService ?? IpService();

    // 1. Get Public IP
    final publicIp = await service.getPublicIp();

    // 2. Resolve Domain IP
    final domainIp = await service.resolveDomainIp(config.domain);

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

    // VERIFICATION STEP:
    // If we are about to update because the IP is different, verify stability.
    if (publicIp != domainIp) {
      await Future.delayed(const Duration(seconds: 5));
      try {
        final verifiedIp = await service.getPublicIp();
        if (verifiedIp != publicIp) {
          return DDNSUpdateResult(
            status:
                "Skipped: Unstable network. IP changed from $publicIp to $verifiedIp.",
            publicIp: verifiedIp,
            success: false,
          );
        }
      } catch (e) {
        // If verification fails, it's also unstable
        return DDNSUpdateResult(
          status: "Skipped: Network error during verification: $e",
          publicIp: publicIp,
          success: false,
        );
      }
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
