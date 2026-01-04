class LogEntry {
  final DateTime time;
  final String status;
  final String message;

  LogEntry({required this.time, required this.status, required this.message});

  Map<String, dynamic> toJson() {
    return {
      'time': time.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      time: DateTime.parse(json['time']),
      status: json['status'],
      message: json['message'],
    );
  }
}

class DDNSConfig {
  final String id;
  final String provider; // e.g. "DuckDNS"
  final String domain;
  final String token;
  final bool isActive;
  final int updateInterval; // In minutes
  final DateTime? lastUpdate;
  final String? lastStatus;
  final List<LogEntry> logs;

  DDNSConfig({
    required this.id,
    required this.provider,
    required this.domain,
    required this.token,
    this.isActive = true,
    this.updateInterval = 15,
    this.lastUpdate,
    this.lastStatus,
    this.logs = const [],
  });

  DDNSConfig copyWith({
    String? id,
    String? provider,
    String? domain,
    String? token,
    bool? isActive,
    int? updateInterval,
    DateTime? lastUpdate,
    String? lastStatus,
    List<LogEntry>? logs,
  }) {
    return DDNSConfig(
      id: id ?? this.id,
      provider: provider ?? this.provider,
      domain: domain ?? this.domain,
      token: token ?? this.token,
      isActive: isActive ?? this.isActive,
      updateInterval: updateInterval ?? this.updateInterval,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastStatus: lastStatus ?? this.lastStatus,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider': provider,
      'domain': domain,
      'token': token,
      'isActive': isActive,
      'updateInterval': updateInterval,
      'lastUpdate': lastUpdate?.toIso8601String(),
      'lastStatus': lastStatus,
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }

  factory DDNSConfig.fromJson(Map<String, dynamic> json) {
    return DDNSConfig(
      id: json['id'],
      provider: json['provider'],
      domain: json['domain'],
      token: json['token'],
      isActive: json['isActive'] ?? true,
      updateInterval: json['updateInterval'] ?? 15,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'])
          : null,
      lastStatus: json['lastStatus'],
      logs:
          (json['logs'] as List<dynamic>?)
              ?.map((e) => LogEntry.fromJson(e))
              .toList() ??
          [],
    );
  }
}
