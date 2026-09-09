class LatencyMetrics {
  final int totalGenerated;
  final double p50Micros;
  final double p90Micros;
  final double p99Micros;
  final double p999Micros;
  final double maxMicros;
  final double meanMicros;

  LatencyMetrics({
    required this.totalGenerated,
    required this.p50Micros,
    required this.p90Micros,
    required this.p99Micros,
    required this.p999Micros,
    required this.maxMicros,
    required this.meanMicros,
  });

  factory LatencyMetrics.fromJson(Map<String, dynamic> json) {
    return LatencyMetrics(
      totalGenerated: json['totalGenerated'] is int ? json['totalGenerated'] : int.tryParse(json['totalGenerated'].toString()) ?? 0,
      p50Micros: (json['p50Micros'] as num?)?.toDouble() ?? 0.0,
      p90Micros: (json['p90Micros'] as num?)?.toDouble() ?? 0.0,
      p99Micros: (json['p99Micros'] as num?)?.toDouble() ?? 0.0,
      p999Micros: (json['p999Micros'] as num?)?.toDouble() ?? 0.0,
      maxMicros: (json['maxMicros'] as num?)?.toDouble() ?? 0.0,
      meanMicros: (json['meanMicros'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
