import 'id_model.dart';

class ClusterStatus {
  final int nodeId;
  final bool isLeader;
  final bool zookeeperConnected;
  final bool redisConnected;
  final String activeStrategy;
  final int epochMillis;
  final List<String> registeredNodes;
  final int totalGenerated;
  final int? lastAllocatedId;
  final int? lastSequence;

  ClusterStatus({
    required this.nodeId,
    required this.isLeader,
    required this.zookeeperConnected,
    required this.redisConnected,
    required this.activeStrategy,
    required this.epochMillis,
    required this.registeredNodes,
    this.totalGenerated = 0,
    this.lastAllocatedId,
    this.lastSequence,
  });

  factory ClusterStatus.fromJson(Map<String, dynamic> json) {
    var nodesList = json['registeredNodes'] as List? ?? [];
    return ClusterStatus(
      nodeId: json['nodeId'] is int ? json['nodeId'] : int.tryParse(json['nodeId']?.toString() ?? '') ?? 0,
      isLeader: json['leader'] == true || json['isLeader'] == true,
      zookeeperConnected: json['zookeeperConnected'] == true,
      redisConnected: json['redisConnected'] == true,
      activeStrategy: json['activeStrategy']?.toString() ?? 'AUTO',
      epochMillis: json['epochMillis'] is int ? json['epochMillis'] : int.tryParse(json['epochMillis']?.toString() ?? '') ?? 0,
      registeredNodes: nodesList.map((e) => e.toString()).toList(),
      totalGenerated: json['totalGenerated'] is int
          ? json['totalGenerated']
          : int.tryParse(json['totalGenerated']?.toString() ?? '0') ?? 0,
      lastAllocatedId: json['lastAllocatedId'] is int
          ? json['lastAllocatedId']
          : int.tryParse(json['lastAllocatedId']?.toString() ?? ''),
      lastSequence: json['lastSequence'] is int
          ? json['lastSequence']
          : int.tryParse(json['lastSequence']?.toString() ?? ''),
    );
  }
}

class NodeInstanceInfo {
  final String id;
  final String label;
  final int port;
  final String baseUrl;
  bool isOnline;
  bool isLeader;
  int nodeId;
  String strategy;
  bool zkConnected;
  bool redisConnected;
  double pingMs;
  String? lastGeneratedId;
  int? lastSequence;
  int generatedCount;
  bool isGenerating;
  bool isStreaming;
  int segmentMin;
  int segmentMax;
  List<String> registeredNodes;
  String? errorMessage;
  IdResponse? lastIdResponse;
  ParsedId? lastParsedId;
  final List<Map<String, String>> nodeFeed = [];

  NodeInstanceInfo({
    required this.id,
    required this.label,
    required this.port,
    required this.baseUrl,
    this.isOnline = false,
    this.isLeader = false,
    this.nodeId = 0,
    this.strategy = 'AUTO',
    this.zkConnected = false,
    this.redisConnected = false,
    this.pingMs = 0.0,
    this.lastGeneratedId,
    this.lastSequence,
    this.generatedCount = 0,
    this.isGenerating = false,
    this.isStreaming = false,
    this.segmentMin = 1,
    this.segmentMax = 1024,
    this.registeredNodes = const [],
    this.errorMessage,
    this.lastIdResponse,
    this.lastParsedId,
  });

  double get segmentUsageRatio {
    if (lastSequence == null || segmentMax <= segmentMin) return 0.0;
    int offset = (lastSequence! - segmentMin + 1);
    if (offset < 0) offset = 0;
    int span = segmentMax - segmentMin + 1;
    if (span <= 0) span = 1024;
    double ratio = (offset % span) / span.toDouble();
    return ratio.clamp(0.0, 1.0);
  }

  void addFeed(String title, String subtitle) {
    nodeFeed.insert(0, {
      'title': title,
      'subtitle': subtitle,
      'time': DateTime.now().toIso8601String().substring(11, 19),
    });
    if (nodeFeed.length > 30) {
      nodeFeed.removeLast();
    }
  }
}
