class EcgSummary {
  final double averageHeartRate;
  final int totalRPeaks;
  final int durationSeconds;
  final int abnormalitiesCount; // For future use, e.g., if we detect PVCs
  final double averageSignalValue;

  EcgSummary({
    required this.averageHeartRate,
    required this.totalRPeaks,
    required this.durationSeconds,
    this.abnormalitiesCount = 0,
    required this.averageSignalValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'averageHeartRate': averageHeartRate,
      'totalRPeaks': totalRPeaks,
      'durationSeconds': durationSeconds,
      'abnormalitiesCount': abnormalitiesCount,
      'averageSignalValue': averageSignalValue,
    };
  }
}
