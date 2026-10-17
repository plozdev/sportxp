enum HealthPermission { unknown, granted, denied, unavailable }

class HealthSummary {
  const HealthSummary({
    required this.start,
    required this.end,
    required this.source,
    this.activeCalories,
    this.averageHeartRate,
  });
  final DateTime start, end;
  final String source;
  final double? activeCalories;
  final int? averageHeartRate;
}

/// Implement with HealthKit / Health Connect; request consent before reading.
abstract interface class HealthGateway {
  Future<HealthPermission> requestReadPermission();
  Future<HealthSummary?> readSession(DateTime start, DateTime end);
}
