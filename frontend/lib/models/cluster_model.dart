class ClusterStatus {
  final int nodeId;
  final bool isLeader;
  final bool zookeeperConnected;
  final bool redisConnected;
  final String activeStrategy;
  final int epochMillis;
  final List<String> registeredNodes;

  ClusterStatus({
    required this.nodeId,
    required this.isLeader,
    required this.zookeeperConnected,
    required this.redisConnected,
    required this.activeStrategy,
    required this.epochMillis,
    required this.registeredNodes,
  });

  factory ClusterStatus.fromJson(Map<String, dynamic> json) {
    var nodesList = json['registeredNodes'] as List? ?? [];
    return ClusterStatus(
      nodeId: json['nodeId'] is int ? json['nodeId'] : int.tryParse(json['nodeId'].toString()) ?? 0,
      isLeader: json['leader'] == true || json['isLeader'] == true,
      zookeeperConnected: json['zookeeperConnected'] == true,
      redisConnected: json['redisConnected'] == true,
      activeStrategy: json['activeStrategy'] ?? 'AUTO',
      epochMillis: json['epochMillis'] is int ? json['epochMillis'] : int.tryParse(json['epochMillis'].toString()) ?? 0,
      registeredNodes: nodesList.map((e) => e.toString()).toList(),
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
  List<String> registeredNodes;
  String? errorMessage;

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
    this.registeredNodes = const [],
    this.errorMessage,
  });
}
