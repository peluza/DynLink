import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/ddns_service.dart';
import '../../services/background_service.dart';
import '../../providers/config_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/ddns_config.dart';
import 'manage_configs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _isBatteryOptimized =
      true; // Default to assuming worst case (optimized = restricted)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBatteryStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBatteryStatus();
    }
  }

  Future<void> _checkBatteryStatus() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) {
      setState(() {
        // If granted, it means we are NOT optimized (good).
        // If denied, it means we ARE optimized (bad).
        _isBatteryOptimized = !status.isGranted;
      });
    }
  }

  Future<void> _saveConfig(BuildContext context) async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);

    if (!homeProvider.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    final newConfig = DDNSConfig(
      id: const Uuid().v4(),
      provider: homeProvider.selectedProvider,
      domain: homeProvider.fullDomain,
      token: homeProvider.tokenController.text.trim(),
      updateInterval: homeProvider.selectedInterval,
      lastStatus: 'Pending...',
    );

    await Provider.of<ConfigProvider>(
      context,
      listen: false,
    ).addConfig(newConfig);

    // Register background task
    await BackgroundService.registerPeriodicTask();

    // Trigger IMMEDIATE update for feedback
    final ddnsService = Provider.of<DDNSService>(context, listen: false);
    final configProvider = Provider.of<ConfigProvider>(context, listen: false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Testing connection...')));

    await ddnsService.performUpdate(newConfig);

    final result = ddnsService.lastStatus;
    // We pass the currentIP from service if available
    await configProvider.logUpdate(
      newConfig.id,
      result,
      DateTime.now(),
      lastKnownIp: ddnsService.currentIP,
    );

    homeProvider.clearForm();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved. Initial Update: ${result.startsWith("Success") ? "Successful" : (result.contains("Skipped") ? "Skipped (IP Synced)" : "Failed")}',
          ),
          backgroundColor:
              (result.startsWith("Success") || result.contains("Skipped"))
              ? Colors.green
              : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ddnsService = Provider.of<DDNSService>(context);
    final homeProvider = Provider.of<HomeProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('DDNS Updater', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              _isBatteryOptimized ? Icons.battery_alert : Icons.battery_full,
              color: _isBatteryOptimized
                  ? Colors.orangeAccent
                  : Colors.greenAccent,
            ),
            tooltip: _isBatteryOptimized
                ? 'Optimize for Background'
                : 'Background Active',
            onPressed: () async {
              if (_isBatteryOptimized) {
                await _requestBatteryExemption(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("App is allowed to run in background"),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            tooltip: 'Manage Accounts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageConfigsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.cloud_sync_outlined,
                    size: 80,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Add New Account', // UI Changed to focus on Adding
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Provider Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: homeProvider.selectedProvider,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.cyanAccent,
                        ),
                        items: homeProvider.providers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.dns,
                                  size: 20,
                                  color: Colors.white54,
                                ),
                                const SizedBox(width: 12),
                                Text(value),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: homeProvider.setProvider,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Interval Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: homeProvider.selectedInterval,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        icon: const Icon(
                          Icons.access_time,
                          color: Colors.cyanAccent,
                        ),
                        items: homeProvider.intervalOptions.map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              'Every ${homeProvider.getIntervalLabel(value)}',
                            ),
                          );
                        }).toList(),
                        onChanged: homeProvider.setInterval,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Configuration Fields
                  TextField(
                    controller: homeProvider.subdomainController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      homeProvider.selectedProvider == 'DuckDNS'
                          ? 'Subdomain (e.g. myhome)'
                          : 'Values',
                      suffix: homeProvider.selectedProvider == 'DuckDNS'
                          ? '.duckdns.org'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: homeProvider.tokenController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Token'),
                    obscureText: true,
                  ),

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _saveConfig(context),
                          style: _buttonStyle(colorScheme.secondary),
                          child: const Text('SAVE & MIGRATE'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final homeProv = Provider.of<HomeProvider>(
                              context,
                              listen: false,
                            );
                            // We construct a temporary config for the test
                            final tempConfig = DDNSConfig(
                              id: 'temp',
                              provider: homeProv.selectedProvider,
                              domain: homeProv.fullDomain,
                              token: homeProv.tokenController.text.trim(),
                            );
                            await ddnsService.performUpdate(tempConfig);
                          },
                          style: _buttonStyle(colorScheme.primary),
                          child: const Text('TEST NOW'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  // Simple Last Status View for immediate feedback
                  Text(
                    'Validation Status: ${ddnsService.lastStatus}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestBatteryExemption(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: const Text(
          "Background Persistence",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "To ensure the app updates your IP reliably in the background, please allow it to ignore battery optimizations.\n\n"
          "1. Click 'OPEN SETTINGS'\n"
          "2. Select 'All apps'\n"
          "3. Find 'DDNS Updater'\n"
          "4. Select 'Don't optimize'",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Request permission directly
                // On Android, this usually opens a system dialog to "Allow" or "Deny"
                var status = await Permission.ignoreBatteryOptimizations
                    .request();

                // If denied or restricted, fall back to general settings
                if (!status.isGranted) {
                  await openAppSettings();
                }

                // Re-check status when coming back
                await _checkBatteryStatus();
              } catch (e) {
                print("Error requesting permission: $e");
                await openAppSettings();
              }
            },
            child: const Text("OPEN SETTINGS"),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.cyanAccent),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}
