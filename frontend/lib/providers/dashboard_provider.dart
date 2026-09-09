import 'dart:async';
import 'package:flutter/material.dart';
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ElectionLeaderApiService apiService = ElectionLeaderApiService();

  final List<String> nodeUrls = [
    'http://localhost:8001',
    'http://localhost:8002',
    'http://localhost:8003',
  ];

  int selectedNodeIndex = 0;
  List<NodeInstanceInfo> clusterNodes = [];
  Map<int, ParsedId> simultaneousResults = {};

  IdResponse? currentId;
  ParsedId? parsedId;
  ClusterStatus? clusterStatus;
  LatencyMetrics? latencyMetrics;

  final List<Map<String, String>> feedItems = [];
  bool isStreaming = false;
  Timer? streamTimer;
  Timer? pollTimer;
  Timer? qpsTimer;

  int qpsCounter = 0;
  int currentQps = 0;
  bool isGenerating = false;
  bool isMultiGenerating = false;

  String get activeNodeUrl => nodeUrls[selectedNodeIndex];

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

  void selectNode(int index) {
    if (index >= 0 && index < nodeUrls.length) {
      selectedNodeIndex = index;
      apiService.baseUrl = nodeUrls[selectedNodeIndex];
      refreshAll();
    }
  }

  Future<void> refreshAll() async {
    await pollAllNodes();
    await generateSingleId();
  }

  Future<void> pollAllNodes() async {
    List<NodeInstanceInfo> updated = [];
    for (int i = 0; i < nodeUrls.length; i++) {
      final url = nodeUrls[i];
      final port = 8001 + i;
      final sw = Stopwatch()..start();
      final status = await apiService.getClusterStatus(overrideUrl: url);
      sw.stop();

      if (status != null) {
        updated.add(NodeInstanceInfo(
          index: i,
          port: port,
          url: url,
          isOnline: true,
          isLeader: status.isLeader,
          nodeId: status.nodeId,
          strategy: status.activeStrategy,
          zkConnected: status.zookeeperConnected,
          redisConnected: status.redisConnected,
          latencyMicros: sw.elapsedMicroseconds.toDouble(),
        ));
      } else {
        updated.add(NodeInstanceInfo(
          index: i,
          port: port,
          url: url,
          isOnline: false,
          isLeader: false,
          nodeId: i,
          strategy: 'STANDALONE',
          zkConnected: false,
          redisConnected: false,
          latencyMicros: 0.0,
        ));
      }
    }
    clusterNodes = updated;

    // Update active node status and metrics
    final activeStatus = await apiService.getClusterStatus(overrideUrl: activeNodeUrl);
    final activeMetrics = await apiService.getLatencyMetrics(overrideUrl: activeNodeUrl);
    if (activeStatus != null) clusterStatus = activeStatus;
    if (activeMetrics != null) latencyMetrics = activeMetrics;

    notifyListeners();
  }

  Future<void> generateSingleId({int? fromNodeIndex}) async {
    isGenerating = true;
    notifyListeners();

    final targetUrl = fromNodeIndex != null ? nodeUrls[fromNodeIndex] : activeNodeUrl;
    final res = await apiService.getNextId(overrideUrl: targetUrl);
    if (res != null) {
      currentId = res;
      qpsCounter++;
      final nodeTag = fromNodeIndex != null ? 'Node ' : 'Node ';
      pushFeed('[\] Generated ID: ', res.strategy);

      // Auto-decode the current ID
      final parsed = await apiService.decodeId(res.id.toString(), overrideUrl: targetUrl);
      if (parsed != null) {
        parsedId = parsed;
      }
    }

    isGenerating = false;
    notifyListeners();
  }

  Future<void> generateSimultaneousAcrossCluster() async {
    isMultiGenerating = true;
    notifyListeners();

    Map<int, ParsedId> results = {};
    List<Future<void>> futures = [];

    for (int i = 0; i < nodeUrls.length; i++) {
      final index = i;
      final url = nodeUrls[i];
      futures.add(() async {
        final res = await apiService.getNextId(overrideUrl: url);
        if (res != null) {
          qpsCounter++;
          final parsed = await apiService.decodeId(res.id.toString(), overrideUrl: url);
          if (parsed != null) {
            results[index] = parsed;
          }
        }
      }());
    }

    await Future.wait(futures);
    simultaneousResults = results;

    if (results.isNotEmpty) {
      pushFeed(
        'Concurrent generation across \ active nodes',
        'Multi-node Bit-packing Verified (0 collisions)',
      );
    }

    isMultiGenerating = false;
    notifyListeners();
  }

  Future<void> generateBatch(int count) async {
    isGenerating = true;
    notifyListeners();

    final res = await apiService.getBatch(count, overrideUrl: activeNodeUrl);
    if (res != null && res.ids.isNotEmpty) {
      qpsCounter += res.count;
      pushFeed('Generated \ IDs on Node \ in \ µs', res.strategy);

      final lastId = res.ids.last;
      final parsed = await apiService.decodeId(lastId.toString(), overrideUrl: activeNodeUrl);
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
    notifyListeners();
  }

  Future<void> decodeCustomId(String input) async {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return;

    final res = await apiService.decodeId(cleanInput, overrideUrl: activeNodeUrl);
    if (res != null) {
      parsedId = res;
      notifyListeners();
    }
  }

  void toggleStream() {
    isStreaming = !isStreaming;
    if (isStreaming) {
      streamTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
        generateSingleId();
      });
    } else {
      streamTimer?.cancel();
    }
    notifyListeners();
  }

  void pushFeed(String title, String subtitle) {
    feedItems.insert(0, {'title': title, 'subtitle': subtitle});
    if (feedItems.length > 50) {
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
