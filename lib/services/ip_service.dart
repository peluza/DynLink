import 'dart:io';
import 'package:dio/dio.dart';

class IpService {
  final Dio _dio;

  IpService({Dio? dio}) : _dio = dio ?? Dio();

  // Failover strategy:
  // 0-15 min: Use icanhazip
  // 15-30 min: Use aws
  // 30-45 min: Use icanhazip
  // 45-60 min: Use aws
  // On failure: Switch to the other immediately

  static const String _service1 = 'https://icanhazip.com';
  static const String _service2 = 'https://checkip.amazonaws.com/';

  Future<String> getPublicIp() async {
    final now = DateTime.now();
    // Determine primary service based on 15-minute intervals
    // 0-14: Service 1
    // 15-29: Service 2
    // 30-44: Service 1
    // 45-59: Service 2
    final isService1Primary = (now.minute ~/ 15) % 2 == 0;

    String primaryUrl = isService1Primary ? _service1 : _service2;
    String secondaryUrl = isService1Primary ? _service2 : _service1;

    try {
      return await _fetchIp(primaryUrl);
    } catch (e) {
      print(
        "Primary IP service ($primaryUrl) failed: $e. Switching to secondary.",
      );
      try {
        return await _fetchIp(secondaryUrl);
      } catch (e2) {
        throw Exception(
          "Both IP services failed. Primary error: $e. Secondary error: $e2",
        );
      }
    }
  }

  Future<String> _fetchIp(String url) async {
    final response = await _dio.get(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data.toString().trim();
  }

  /// Resolves the current IP of the domain using DNS lookup
  Future<String?> resolveDomainIp(String domain) async {
    try {
      // Clean domain if it has http/https
      String cleanDomain = domain
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .split('/')[0];

      final List<InternetAddress> addresses = await InternetAddress.lookup(
        cleanDomain,
      );
      if (addresses.isNotEmpty) {
        return addresses.first.address;
      }
      return null;
    } catch (e) {
      print("DNS resolution failed for $domain: $e");
      return null;
    }
  }
}
