import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/config_provider.dart';
import 'config_details_screen.dart';

class ManageConfigsScreen extends StatefulWidget {
  const ManageConfigsScreen({super.key});

  @override
  State<ManageConfigsScreen> createState() => _ManageConfigsScreenState();
}

class _ManageConfigsScreenState extends State<ManageConfigsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh configs from disk to catch any background updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ConfigProvider>(context, listen: false).loadConfigs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Manage Accounts', style: GoogleFonts.outfit()),
        backgroundColor: Colors.transparent,
      ),
      body: Consumer<ConfigProvider>(
        builder: (context, manager, child) {
          if (manager.configs.isEmpty) {
            return Center(
              child: Text(
                'No accounts configured.\nGo back to add one.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: manager.configs.length,
            itemBuilder: (context, index) {
              final config = manager.configs[index];
              return Card(
                color: const Color(0xFF1E1E1E),
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ConfigDetailsScreen(configId: config.id),
                      ),
                    );
                  },
                  title: Text(
                    config.domain,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider: ${config.provider}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Last Status: ${config.lastStatus ?? "Waiting..."}',
                        style: TextStyle(
                          color:
                              (config.lastStatus?.startsWith('Success') ??
                                  false)
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      manager.removeConfig(config.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
