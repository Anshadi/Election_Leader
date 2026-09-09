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
