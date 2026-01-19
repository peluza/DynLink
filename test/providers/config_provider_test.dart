import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ddns_updater/providers/config_provider.dart';
import 'package:ddns_updater/models/ddns_config.dart';

void main() {
  late ConfigProvider provider;

  setUp(() {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    provider = ConfigProvider();
  });

  group('ConfigProvider Tests', () {
    final defaultConfig = DDNSConfig(
      id: '1',
      domain: 'test.duckdns.org',
      token: 'token',
      provider: 'DuckDNS',
      logs: [],
    );

    test('addConfig adds config and saves to storage', () async {
      await provider.addConfig(defaultConfig);

      expect(provider.configs.length, 1);
      expect(provider.configs.first.domain, 'test.duckdns.org');

      // Verify storage
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('saved_configs_v2');
      expect(stored, contains('test.duckdns.org'));
    });

    test('removeConfig removies config from storage', () async {
      await provider.addConfig(defaultConfig);
      await provider.removeConfig('1');

      expect(provider.configs.isEmpty, true);
    });

    test('updateConfig modifies existing config', () async {
      await provider.addConfig(defaultConfig);

      final updatedConfig = defaultConfig.copyWith(token: 'newToken');
      await provider.updateConfig(updatedConfig);

      expect(provider.configs.first.token, 'newToken');
    });

    test('loadConfigs restores state from storage', () async {
      // Pre-populate storage
      // We need to use valid JSON for DDNSConfig
      // But creating json manually is tedious.
      // Let's use the provider to save, then creating a NEW provider to load.

      await provider.addConfig(defaultConfig);

      final newProvider = ConfigProvider();
      await newProvider.loadConfigs();

      expect(newProvider.configs.length, 1);
      expect(newProvider.configs.first.domain, 'test.duckdns.org');
    });
  });
}
