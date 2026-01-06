import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:ddns_updater/services/ddns_service.dart';
import 'package:ddns_updater/providers/config_provider.dart';

const String simplePeriodicTask = "simplePeriodicTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // CRITICAL: Initialize Flutter bindings for SharedPreferences to work in background!
    WidgetsFlutterBinding.ensureInitialized();

    print("Native called background task: $task");
    try {
      // 1. Get all saved configs
      final configs = await ConfigProvider.getConfigsStatic();

      if (configs.isEmpty) {
        print("No configs found to update.");
        return Future.value(true);
      }

      int successCount = 0;

      // 2. Iterate and update each active config
      for (final config in configs) {
        if (!config.isActive) continue;

        // Check if enough time has passed based on config.updateInterval
        if (config.lastUpdate != null) {
          final timeSinceLast = DateTime.now().difference(config.lastUpdate!);
          if (timeSinceLast.inMinutes < config.updateInterval) {
            print(
              "Skipping ${config.domain}: Updated ${timeSinceLast.inMinutes}m ago (Interval: ${config.updateInterval}m)",
            );
            continue;
          }
        }

        try {
          // TODO: Use provider factory when we have more providers
          // For now assuming DuckDNS based on config.provider or default
          final result = await DDNSService.backgroundUpdate(config);

          await ConfigProvider.updateStatusStatic(
            config.id,
            result.status,
            DateTime.now(),
            lastKnownIp: result.publicIp,
            // Only update lastSuccessUpdate if we strictly updated or verified successful state
            // Logic: if result.success is true, we consider it a success.
            // But strict 15-day rule depends on "actual update".
            // If we skipped, we update 'lastUpdate' (last check), but do we update 'lastSuccessUpdate'?
            // The user said: "almacenar la fecha de del cambio de ip".
            // So lastSuccessUpdate should probably only be updated when IP *actually changes* or forced.
            // But we also need to know when we *checked* for the skip logic.
            // `DDNSConfig` has `lastUpdate` and `lastSuccessUpdate`.
            // `lastUpdate` = last time we ran the check.
            // `lastSuccessUpdate` = last time we performed a successful sync with provider?
            // "al dia 15 de no actualizar la ip debes hacerlo" -> implies lastSuccessUpdate tracks the actual change.
            // So if we SKIP, we DO NOT update lastSuccessUpdate.
            // We only update lastSuccessUpdate if result.status contains "Success" (from provider) AND it wasn't a skip.
            // In my DDNSService, skip returns success=true.
            // Let's rely on status string content or refine DDNSUpdateResult?
            // "Skipped" is in the status.
            lastSuccessUpdate: result.status.contains('Skipped')
                ? null
                : DateTime.now(),
          );
          successCount++;
        } catch (e) {
          print("Failed to update ${config.domain}: $e");
          await ConfigProvider.updateStatusStatic(
            config.id,
            "Error: $e",
            DateTime.now(),
          );
        }
      }

      print(
        "Background update completed. Updated $successCount/${configs.length}",
      );
      return Future.value(true);
    } catch (e) {
      print("CRITICAL Background task failed: $e");
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  }

  static Future<void> registerPeriodicTask() async {
    await Workmanager().registerPeriodicTask(
      "1",
      simplePeriodicTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy:
          ExistingPeriodicWorkPolicy.update, // Update policy to ensure it runs
    );
  }
}
