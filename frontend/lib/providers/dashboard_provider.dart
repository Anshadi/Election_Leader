import 'dart:async';
import 'package:flutter/material.dart';
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ElectionLeaderApiService apiService = ElectionLeaderApiService();

  final List<NodeInstanceInfo> nodes = [
    NodeInstanceInfo(id: 'node-1', label: 'Node 1', port: 8001, baseUrl: 'http://localhost:8001', segmentMin: 1, segmentMax: 1024),
    NodeInstanceInfo(id: 'node-2', label: 'Node 2', port: 8002, baseUrl: 'http://localhost:8002', segmentMin: 1025, segmentMax: 2048),
    NodeInstanceInfo(id: 'node-3', label: 'Node 3', port: 8003, baseUrl: 'http://localhost:8003', segmentMin: 2049, segmentMax: 3072),
  ];

  int selectedNodeIndex = 0;
  NodeInstanceInfo get activeNode => nodes[selectedNodeIndex];

  String selectedLogFilter = 'ALL';

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
  bool isClusterStreaming = false;
  final Map<int, Timer> _nodeStreamTimers = {};

  Timer? pollTimer;
  Timer? qpsTimer;

  int qpsCounter = 0;
  int currentQps = 0;
  bool isGenerating = false;
  bool isBroadcasting = false;

  bool get isStreaming => activeNode.isStreaming || isClusterStreaming;

  List<Map<String, String>> get filteredFeedItems {
    if (selectedLogFilter == 'ALL') {
      return feedItems;
    }
    return feedItems.where((item) => item['nodeId'] == selectedLogFilter).toList();
  }

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
      pushFeed('Switched active target to ${nodes[index].label} (:${nodes[index].port})', 'Target endpoint updated', nodeId: nodes[index].id);
      notifyListeners();
    }
  }

  void setLogFilter(String filter) {
    selectedLogFilter = filter;
    notifyListeners();
  }

  Future<void> generateSingleId({bool isManual = false, int? nodeIndex}) async {
    final int targetIndex = (nodeIndex != null && nodeIndex >= 0 && nodeIndex < nodes.length)
        ? nodeIndex
        : selectedNodeIndex;
    final targetNode = nodes[targetIndex];

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

      if (res.sequence > targetNode.segmentMax) {
        int steps = ((res.sequence - targetNode.segmentMin) / 1024).floor();
        targetNode.segmentMin = 1 + steps * 1024;
        targetNode.segmentMax = (steps + 1) * 1024;
      }

      final title = 'Generated ID: ${res.id} [${targetNode.label}]';
      final subtitle = 'Node #${res.nodeId} | Seq: #${res.sequence} | ${res.strategy}';

      pushFeed(title, subtitle, nodeId: targetNode.id);
      targetNode.addFeed(title, subtitle);

      final parsed = await apiService.decodeId(res.id.toString(), baseUrl: targetNode.baseUrl);
      if (parsed != null) {
        parsedId = parsed;
      } else {
        parsedId = ParsedId.parseLocal(res.id);
      }
    } else {
      final failTitle = 'Failed to generate on ${targetNode.label}';
      final failSub = 'Target ${targetNode.baseUrl} unreachable';
      pushFeed(failTitle, failSub, nodeId: targetNode.id);
      targetNode.addFeed(failTitle, failSub);
    }

    if (isManual) {
      isGenerating = false;
      targetNode.isGenerating = false;
    }
    notifyListeners();
  }

  Future<void> generateBatch(int count, {int? nodeIndex}) async {
    final int targetIndex = (nodeIndex != null && nodeIndex >= 0 && nodeIndex < nodes.length)
        ? nodeIndex
        : selectedNodeIndex;
    final targetNode = nodes[targetIndex];

    isGenerating = true;
    targetNode.isGenerating = true;
    notifyListeners();

    final res = await apiService.getBatch(count, baseUrl: targetNode.baseUrl);
    if (res != null && res.ids.isNotEmpty) {
      qpsCounter += res.count;
      targetNode.generatedCount += res.count;
      targetNode.lastGeneratedId = res.ids.last.toString();
      targetNode.lastSequence = res.ids.last;

      final title = 'Batch: generated ${res.count} IDs on ${targetNode.label}';
      final subtitle = 'Duration: ${res.durationMicros.toStringAsFixed(1)} µs | ${res.strategy}';

      pushFeed(title, subtitle, nodeId: targetNode.id);
      targetNode.addFeed(title, subtitle);

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
      } else {
        parsedId = ParsedId.parseLocal(lastId);
        currentId = IdResponse(
          id: lastId,
          timestamp: parsedId!.absoluteTimestamp,
          dateTime: parsedId!.dateTime,
          nodeId: parsedId!.nodeId,
          sequence: parsedId!.sequence,
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
      nodes.asMap().entries.map((entry) async {
        final node = entry.value;
        if (!node.isOnline) return null;
        node.isGenerating = true;
        final res = await apiService.getNextId(baseUrl: node.baseUrl);
        node.isGenerating = false;
        if (res != null) {
          node.lastGeneratedId = res.id.toString();
          node.lastSequence = res.sequence;
          node.generatedCount++;
          qpsCounter++;
          final title = 'Broadcast ID: ${res.id} [${node.label}]';
          final sub = 'Seq: #${res.sequence} | Node #${res.nodeId}';
          node.addFeed(title, sub);
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
        '⚡ Broadcast: Generated ${successful.length} IDs across cluster concurrently',
        'Time: $elapsed ms | $collisionText',
      );

      for (final res in successful) {
        final node = nodes.firstWhere((n) => n.nodeId == res.nodeId, orElse: () => nodes[0]);
        pushFeed(
          'Node #${res.nodeId} (${node.label}) -> ID: ${res.id}',
          'Seq: #${res.sequence} | Strategy: ${res.strategy}',
          nodeId: node.id,
        );
      }

      currentId = successful.last;
      final parsed = await apiService.decodeId(successful.last.id.toString(), baseUrl: activeNode.baseUrl);
      if (parsed != null) {
        parsedId = parsed;
      } else {
        parsedId = ParsedId.parseLocal(successful.last.id);
      }
    } else {
      pushFeed('Broadcast Failed', 'No active nodes responded');
    }

    isBroadcasting = false;
    notifyListeners();
  }

  Future<void> decodeCustomId(String input) async {
    final cleanInput = input.trim().replaceAll(',', '').replaceAll(' ', '');
    if (cleanInput.isEmpty) return;

    final parsedNumber = int.tryParse(cleanInput);

    final res = await apiService.decodeId(cleanInput, baseUrl: activeNode.baseUrl);
    if (res != null) {
      parsedId = res;
      currentId = IdResponse(
        id: res.id,
        timestamp: res.absoluteTimestamp,
        dateTime: res.dateTime,
        nodeId: res.nodeId,
        sequence: res.sequence,
        strategy: 'DECODED_ID',
      );
      pushFeed('Decoded ID: ${res.id}', 'Node: #${res.nodeId} | Seq: #${res.sequence} | Delta: ${res.timestampDelta}ms', nodeId: activeNode.id);
      notifyListeners();
      return;
    }

    if (parsedNumber != null) {
      final local = ParsedId.parseLocal(parsedNumber);
      parsedId = local;
      currentId = IdResponse(
        id: local.id,
        timestamp: local.absoluteTimestamp,
        dateTime: local.dateTime,
        nodeId: local.nodeId,
        sequence: local.sequence,
        strategy: 'DECODED_BITPACK',
      );
      pushFeed('Decoded ID: ${local.id}', 'Node: #${local.nodeId} | Seq: #${local.sequence} | Delta: ${local.timestampDelta}ms', nodeId: activeNode.id);
      notifyListeners();
      return;
    }

    pushFeed('Decode Failed', 'Invalid 64-bit integer input: $cleanInput');
    notifyListeners();
  }

  void toggleNodeStream(int index) {
    if (index < 0 || index >= nodes.length) return;
    final node = nodes[index];

    if (node.isStreaming) {
      node.isStreaming = false;
      _nodeStreamTimers[index]?.cancel();
      _nodeStreamTimers.remove(index);
      pushFeed('Stopped stream on ${node.label}', 'Standby mode', nodeId: node.id);
    } else {
      node.isStreaming = true;
      pushFeed('Started real-time streaming on ${node.label}', 'Target: ~15 QPS', nodeId: node.id);
      _nodeStreamTimers[index] = Timer.periodic(const Duration(milliseconds: 70), (_) {
        generateSingleId(isManual: false, nodeIndex: index);
      });
    }
    notifyListeners();
  }

  void toggleClusterStream() {
    isClusterStreaming = !isClusterStreaming;
    if (isClusterStreaming) {
      pushFeed('⚡ Started Parallel Cluster Stream', 'Streaming across ALL online nodes simultaneously');
      for (int i = 0; i < nodes.length; i++) {
        if (nodes[i].isOnline && !nodes[i].isStreaming) {
          nodes[i].isStreaming = true;
          final idx = i;
          _nodeStreamTimers[idx] = Timer.periodic(const Duration(milliseconds: 80), (_) {
            generateSingleId(isManual: false, nodeIndex: idx);
          });
        }
      }
    } else {
      pushFeed('⏹ Stopped Parallel Cluster Stream', 'All nodes in standby');
      for (int i = 0; i < nodes.length; i++) {
        nodes[i].isStreaming = false;
        _nodeStreamTimers[i]?.cancel();
      }
      _nodeStreamTimers.clear();
    }
    notifyListeners();
  }

  void toggleStream() {
    toggleNodeStream(selectedNodeIndex);
  }

  void pushFeed(String title, String subtitle, {String? nodeId}) {
    feedItems.insert(0, {
      'title': title,
      'subtitle': subtitle,
      'nodeId': nodeId ?? 'ALL',
      'time': DateTime.now().toIso8601String().substring(11, 19),
    });
    if (feedItems.length > 120) {
      feedItems.removeLast();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final timer in _nodeStreamTimers.values) {
      timer.cancel();
    }
    _nodeStreamTimers.clear();
    pollTimer?.cancel();
    qpsTimer?.cancel();
    super.dispose();
  }
}
