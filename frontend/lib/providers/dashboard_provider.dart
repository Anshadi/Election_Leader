import 'dart:async';
import 'package:flutter/material.dart';
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ElectionLeaderApiService apiService = ElectionLeaderApiService();

  final List<NodeInstanceInfo> nodes = [
    NodeInstanceInfo(id: 'node-1', label: 'Node 1', port: 8001, baseUrl: 'http://localhost:8001'),
    NodeInstanceInfo(id: 'node-2', label: 'Node 2', port: 8002, baseUrl: 'http://localhost:8002'),
    NodeInstanceInfo(id: 'node-3', label: 'Node 3', port: 8003, baseUrl: 'http://localhost:8003'),
  ];

  int selectedNodeIndex = 0;
  NodeInstanceInfo get activeNode => nodes[selectedNodeIndex];

  ClusterStatus? get clusterStatus {
    for (final node in nodes) {
      if (node.isOnline) {
        return ClusterStatus(
          nodeId: activeNode.nodeId,
          isLeader: activeNode.isLeader,
          zookeeperConnected: activeNode.zkConnected,
          redisConnected: activeNode.redisConnected,
          activeStrategy: activeNode.strategy,
          epochMillis: DateTime.now().millisecondsSinceEpoch,
          registeredNodes: activeNode.registeredNodes,
        );
      }
    }
    return null;
  }

  IdResponse? currentId;
  ParsedId? parsedId;
  LatencyMetrics? latencyMetrics;

  final List<Map<String, String>> feedItems = [];
  bool isStreaming = false;
  Timer? streamTimer;
  Timer? pollTimer;
  Timer? qpsTimer;

  int qpsCounter = 0;
  int currentQps = 0;
  bool isGenerating = false;
  bool isBroadcasting = false;

  DashboardProvider() {
    init();
  }

  void init() {
    refreshAll();
    pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      pollAllNodes();
    });
    qpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentQps = qpsCounter;
      qpsCounter = 0;
      notifyListeners();
    });
  }

  Future<void> refreshAll() async {
    await pollAllNodes();
    await generateSingleId(isManual: true);
  }

  Future<void> pollAllNodes() async {
    final futures = nodes.map((node) async {
      final sw = Stopwatch()..start();
      final status = await apiService.getClusterStatus(baseUrl: node.baseUrl);
      sw.stop();

      if (status != null) {
        node.isOnline = true;
        node.isLeader = status.isLeader;
        node.nodeId = status.nodeId;
        node.strategy = status.activeStrategy;
        node.zkConnected = status.zookeeperConnected;
        node.redisConnected = status.redisConnected;
        node.registeredNodes = status.registeredNodes;
        node.pingMs = sw.elapsedMicroseconds / 1000.0;
        node.errorMessage = null;
      } else {
        node.isOnline = false;
        node.isLeader = false;
        node.pingMs = 0.0;
        node.errorMessage = 'Connection refused / offline';
      }
    }).toList();

    await Future.wait(futures);

    final targetBaseUrl = activeNode.isOnline ? activeNode.baseUrl : (nodes.firstWhere((n) => n.isOnline, orElse: () => nodes[0]).baseUrl);
    final metrics = await apiService.getLatencyMetrics(baseUrl: targetBaseUrl);
    if (metrics != null) {
      latencyMetrics = metrics;
    }

    notifyListeners();
  }

  void selectNode(int index) {
    if (index >= 0 && index < nodes.length) {
      selectedNodeIndex = index;
      pushFeed('Switched active node to  (:)', 'Target endpoint updated');
      notifyListeners();
    }
  }

  Future<void> generateSingleId({bool isManual = false, int? nodeIndex}) async {
    final targetNode = (nodeIndex != null && nodeIndex >= 0 && nodeIndex < nodes.length)
        ? nodes[nodeIndex]
        : activeNode;

    if (isManual) {
      isGenerating = true;
      targetNode.isGenerating = true;
      notifyListeners();
    }

    final res = await apiService.getNextId(baseUrl: targetNode.baseUrl);
    if (res != null) {
      currentId = res;
      qpsCounter++;
      targetNode.lastGeneratedId = res.id.toString();
      targetNode.lastSequence = res.sequence;
      targetNode.generatedCount++;

      pushFeed(
        'Generated ID:  []',
        'Node # | Seq:  | ',
      );

      final parsed = await apiService.decodeId(res.id.toString(), baseUrl: targetNode.baseUrl);
      if (parsed != null) {
        parsedId = parsed;
      }
    } else {
      pushFeed('Failed to generate on ', 'Target  unreachable');
    }

    if (isManual) {
      isGenerating = false;
      targetNode.isGenerating = false;
    }
    notifyListeners();
  }

  Future<void> generateBatch(int count, {int? nodeIndex}) async {
    final targetNode = (nodeIndex != null && nodeIndex >= 0 && nodeIndex < nodes.length)
        ? nodes[nodeIndex]
        : activeNode;

    isGenerating = true;
    targetNode.isGenerating = true;
    notifyListeners();

    final res = await apiService.getBatch(count, baseUrl: targetNode.baseUrl);
    if (res != null && res.ids.isNotEmpty) {
      qpsCounter += res.count;
      targetNode.generatedCount += res.count;
      targetNode.lastGeneratedId = res.ids.last.toString();

      pushFeed(
        'Batch: generated  IDs on ',
        'Duration:  µs | Strategy: ',
      );

      final lastId = res.ids.last;
      final parsed = await apiService.decodeId(lastId.toString(), baseUrl: targetNode.baseUrl);
      if (parsed != null) {
        parsedId = parsed;
        currentId = IdResponse(
          id: parsed.id,
          timestamp: parsed.absoluteTimestamp,
          dateTime: parsed.dateTime,
          nodeId: parsed.nodeId,
          sequence: parsed.sequence,
          strategy: res.strategy,
        );
      }
    }

    isGenerating = false;
    targetNode.isGenerating = false;
    notifyListeners();
  }

  Future<void> broadcastGenerateAll() async {
    isBroadcasting = true;
    notifyListeners();

    final sw = Stopwatch()..start();
    final results = await Future.wait(
      nodes.map((node) async {
        if (!node.isOnline) return null;
        node.isGenerating = true;
        final res = await apiService.getNextId(baseUrl: node.baseUrl);
        node.isGenerating = false;
        if (res != null) {
          node.lastGeneratedId = res.id.toString();
          node.lastSequence = res.sequence;
          node.generatedCount++;
          qpsCounter++;
        }
        return res;
      }),
    );
    sw.stop();

    final successful = results.whereType<IdResponse>().toList();
    if (successful.isNotEmpty) {
      final uniqueIds = successful.map((r) => r.id).toSet();
      final hasZeroCollision = uniqueIds.length == successful.length;
      final collisionText = hasZeroCollision ? '0% Collision (All Distinct)' : 'Collision Detected!';
      final elapsed = (sw.elapsedMicroseconds / 1000.0).toStringAsFixed(1);

      pushFeed(
        '? Broadcast: Generated ${successful.length} IDs across cluster concurrently',
        'Time: $elapsed ms | $collisionText',
      );

      currentId = successful.last;
      final parsed = await apiService.decodeId(successful.last.id.toString(), baseUrl: activeNode.baseUrl);
      if (parsed != null) {
        parsedId = parsed;
      }
    } else {
      pushFeed('Broadcast Failed', 'No active nodes responded');
    }

    isBroadcasting = false;
    notifyListeners();
  }

  Future<void> decodeCustomId(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    final res = await apiService.decodeId(cleanInput, baseUrl: activeNode.baseUrl);
    if (res != null) {
      parsedId = res;
      pushFeed('Decoded ID: ', 'Node: # | Seq: #');
      notifyListeners();
    }
  }

  void toggleStream() {
    isStreaming = !isStreaming;
    if (isStreaming) {
      pushFeed('Started real-time streaming on ', 'Target: ~100 QPS');
      streamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        generateSingleId(isManual: false);
      });
    } else {
      pushFeed('Stopped real-time streaming', 'Standby mode');
      streamTimer?.cancel();
    }
    notifyListeners();
  }

  void pushFeed(String title, String subtitle) {
    feedItems.insert(0, {'title': title, 'subtitle': subtitle});
    if (feedItems.length > 80) {
      feedItems.removeLast();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    streamTimer?.cancel();
    pollTimer?.cancel();
    qpsTimer?.cancel();
    super.dispose();
  }
}
