class IdResponse {
  final int id;
  final int timestamp;
  final String dateTime;
  final int nodeId;
  final int sequence;
  final String strategy;

  IdResponse({
    required this.id,
    required this.timestamp,
    required this.dateTime,
    required this.nodeId,
    required this.sequence,
    required this.strategy,
  });

  factory IdResponse.fromJson(Map<String, dynamic> json) {
    return IdResponse(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      timestamp: json['timestamp'] is int ? json['timestamp'] : int.tryParse(json['timestamp'].toString()) ?? 0,
      dateTime: json['dateTime'] ?? '',
      nodeId: json['nodeId'] is int ? json['nodeId'] : int.tryParse(json['nodeId'].toString()) ?? 0,
      sequence: json['sequence'] is int ? json['sequence'] : int.tryParse(json['sequence'].toString()) ?? 0,
      strategy: json['strategy'] ?? 'UNKNOWN',
    );
  }
}

class ParsedId {
  final int id;
  final int epochMillis;
  final int timestampDelta;
  final int absoluteTimestamp;
  final String dateTime;
  final int nodeId;
  final int sequence;
  final String binaryRepresentation;

  ParsedId({
    required this.id,
    required this.epochMillis,
    required this.timestampDelta,
    required this.absoluteTimestamp,
    required this.dateTime,
    required this.nodeId,
    required this.sequence,
    required this.binaryRepresentation,
  });

  factory ParsedId.fromJson(Map<String, dynamic> json) {
    return ParsedId(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      epochMillis: json['epochMillis'] is int ? json['epochMillis'] : int.tryParse(json['epochMillis'].toString()) ?? 0,
      timestampDelta: json['timestampDelta'] is int ? json['timestampDelta'] : int.tryParse(json['timestampDelta'].toString()) ?? 0,
      absoluteTimestamp: json['absoluteTimestamp'] is int ? json['absoluteTimestamp'] : int.tryParse(json['absoluteTimestamp'].toString()) ?? 0,
      dateTime: json['dateTime'] ?? '',
      nodeId: json['nodeId'] is int ? json['nodeId'] : int.tryParse(json['nodeId'].toString()) ?? 0,
      sequence: json['sequence'] is int ? json['sequence'] : int.tryParse(json['sequence'].toString()) ?? 0,
      binaryRepresentation: json['binaryRepresentation'] ?? '',
    );
  }
}

class BatchResponse {
  final List<int> ids;
  final int count;
  final String strategy;
  final double durationMicros;

  BatchResponse({
    required this.ids,
    required this.count,
    required this.strategy,
    required this.durationMicros,
  });

  factory BatchResponse.fromJson(Map<String, dynamic> json) {
    var rawList = json['ids'] as List? ?? [];
    List<int> parsedIds = rawList.map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0).toList();
    return BatchResponse(
      ids: parsedIds,
      count: json['count'] ?? parsedIds.length,
      strategy: json['strategy'] ?? '',
      durationMicros: (json['durationMicros'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
