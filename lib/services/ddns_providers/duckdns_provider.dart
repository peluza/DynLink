import 'package:dio/dio.dart';
import 'ddns_provider.dart';

class DuckDNSProvider implements DDNSProvider {
  final Dio _dio = Dio();

  @override
  String get name => 'DuckDNS';

  @override
  Future<String> updateIP(String domain, String token) async {
    try {
      // DuckDNS API prefers just the subdomain (e.g., "myhome")
      // If we send "myhome.duckdns.org", it might return KO.
      String cleanDomain = domain.toLowerCase().replaceAll('.duckdns.org', '');
      // Aggressive token cleaning
      String cleanToken = token
          .trim()
          .replaceAll('token=', '')
          .replaceAll('Token=', '');

      final url =
          'https://duckdns.org/update?domains=$cleanDomain&token=${cleanToken.substring(0, 4)}...';
      print('Attempting update: $url');

      final params = {'domains': cleanDomain, 'token': cleanToken};
      // Only include 'ip' if we actually have one to set.
      // DuckDNS auto-detects if 'ip' is omitted. Sending 'ip=' might cause KO.
      // if (ip.isNotEmpty) params['ip'] = ip;

      final response = await _dio.get(
        'https://duckdns.org/update',
        queryParameters: params,
      );

      if (response.data.toString().trim() == 'OK') {
        return 'Success: IP updated at ${DateTime.now()}';
      } else {
        throw Exception(
          'DuckDNS Error: KO.\nDomain: "$cleanDomain"\nToken Len: ${cleanToken.length} (Expected 36)\nResponse: ${response.data}',
        );
      }
    } catch (e) {
      // Re-throw with more context if it's not the specific one above
      if (e.toString().contains('DuckDNS Error')) rethrow;
      throw Exception('Failed to update DuckDNS: $e');
    }
  }

  @override
  Future<String?> getExternalIP() async {
    try {
      // Using a simple IP echo service or DuckDNS's own response if we parsed it,
      // but for now, let's use a standard public IP checker.
      final response = await _dio.get('https://api.ipify.org');
      return response.data.toString();
    } catch (e) {
      return null; // Fail silently for IP check
    }
  }
}
