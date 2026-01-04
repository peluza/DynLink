import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/ddns_config.dart';
import '../../providers/config_provider.dart';
import '../../services/ddns_service.dart';

class ConfigDetailsScreen extends StatelessWidget {
  final String configId;

  const ConfigDetailsScreen({super.key, required this.configId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigProvider>(
      builder: (context, provider, child) {
        final configIndex = provider.configs.indexWhere(
          (c) => c.id == configId,
        );

        if (configIndex == -1) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(child: Text("Account not found")),
          );
        }

        final config = provider.configs[configIndex];

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: Text('Account Details', style: GoogleFonts.outfit()),
            backgroundColor: Colors.transparent,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Info
                _buildInfoCard(context, config),
                const SizedBox(height: 24),
                Text(
                  'Activity Log',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Logs List
                Expanded(
                  child: config.logs.isEmpty
                      ? Center(
                          child: Text(
                            'No logs yet.',
                            style: GoogleFonts.outfit(color: Colors.white38),
                          ),
                        )
                      : ListView.builder(
                          itemCount: config.logs.length,
                          itemBuilder: (context, index) {
                            final log = config.logs[index];
                            final isSuccess = log.status == 'Success';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(8),
                                border: Border(
                                  left: BorderSide(
                                    color: isSuccess
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.status,
                                        style: GoogleFonts.outfit(
                                          color: isSuccess
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'MMM d, HH:mm:ss',
                                        ).format(log.time),
                                        style: const TextStyle(
                                          color: Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    log.message,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.cyanAccent,
            onPressed: () async {
              final ddnsService = Provider.of<DDNSService>(
                context,
                listen: false,
              );
              final configProvider = Provider.of<ConfigProvider>(
                context,
                listen: false,
              );

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Updating...')));

              await ddnsService.performUpdate(config.domain, config.token);

              final result = ddnsService.lastStatus;

              await configProvider.logUpdate(config.id, result, DateTime.now());
            },
            child: const Icon(Icons.refresh, color: Colors.black),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, DDNSConfig config) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow('Domain', config.domain),
            const Divider(color: Colors.white10),
            _buildRow('Provider', config.provider),
            const Divider(color: Colors.white10),
            _buildRow('Interval', '${config.updateInterval} min'),
            const Divider(color: Colors.white10),
            _buildRow('Status', config.isActive ? 'Active' : 'Paused'),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54)),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
