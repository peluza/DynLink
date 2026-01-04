/// Abstract base class for all DDNS providers.
/// This allows us to easily add more providers (No-IP, DynDNS, etc.) in the future.
abstract class DDNSProvider {
  /// The specific name of the provider (e.g., "DuckDNS")
  String get name;

  /// Updates the DDNS record.
  /// [domain]: The user's domain.
  /// [token]: The authentication token or password.
  /// Returns detailed result string or throws exception on failure.
  Future<String> updateIP(String domain, String token);

  /// Helper to get current external IP (useful for logs/UI).
  Future<String?> getExternalIP();
}
