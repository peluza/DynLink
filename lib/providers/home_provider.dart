import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier {
  final TextEditingController subdomainController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();

  String _selectedProvider = 'DuckDNS';
  final List<String> _providers = ['DuckDNS'];

  // Interval Selection Logic
  int _selectedInterval = 15; // default 15 minutes
  final List<int> _intervalOptions = [
    15,
    30,
    60,
    720,
    1440,
  ]; // Minutes: 15m, 30m, 1h, 12h, 24h

  String get selectedProvider => _selectedProvider;
  List<String> get providers => _providers;

  int get selectedInterval => _selectedInterval;
  List<int> get intervalOptions => _intervalOptions;

  void setProvider(String? newValue) {
    if (newValue != null) {
      _selectedProvider = newValue;
      notifyListeners();
    }
  }

  void setInterval(int? newValue) {
    if (newValue != null) {
      _selectedInterval = newValue;
      notifyListeners();
    }
  }

  String getIntervalLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes Minutes';
    } else if (minutes == 60) {
      return '1 Hour';
    } else {
      return '${minutes ~/ 60} Hours';
    }
  }

  String get fullDomain {
    final sub = subdomainController.text.trim();
    if (sub.isEmpty) return '';
    if (_selectedProvider == 'DuckDNS') {
      if (sub.endsWith('.duckdns.org')) return sub;
      return '$sub.duckdns.org';
    }
    return sub;
  }

  bool get isValid {
    return subdomainController.text.trim().isNotEmpty &&
        tokenController.text.trim().isNotEmpty;
  }

  void clearForm() {
    subdomainController.clear();
    // tokenController.clear(); // Keeping token as per previous logic
    // Reset to default
    _selectedInterval = 15;
    notifyListeners();
  }

  @override
  void dispose() {
    subdomainController.dispose();
    tokenController.dispose();
    super.dispose();
  }
}
