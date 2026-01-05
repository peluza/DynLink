import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../services/ddns_service.dart';
import '../../services/background_service.dart';
import '../../providers/config_provider.dart';
import '../../providers/home_provider.dart';
import '../../models/ddns_config.dart';
import 'manage_configs_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

    await ddnsService.performUpdate(newConfig.domain, newConfig.token);

    final result = ddnsService.lastStatus;
    await configProvider.logUpdate(newConfig.id, result, DateTime.now());

    homeProvider.clearForm();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved. Initial Update: ${result.startsWith("Success") ? "Successful" : "Failed"}',
          ),
          backgroundColor: result.startsWith("Success")
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
                            await ddnsService.performUpdate(
                              homeProv.fullDomain,
                              homeProv.tokenController.text.trim(),
                            );
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
