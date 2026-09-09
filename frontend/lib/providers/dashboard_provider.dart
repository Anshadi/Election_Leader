import 'dart:async';
import 'package:flutter/material.dart';
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ElectionLeaderApiService apiService = ElectionLeaderApiService();

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

  DashboardProvider() {
    init();
  }

  void init() {
    refreshAll();
    pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      pollClusterAndMetrics();
    });
    qpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      currentQps = qpsCounter;
      qpsCounter = 0;
      notifyListeners();
    });
  }

  Future<void> refreshAll() async {
    await pollClusterAndMetrics();
    await generateSingleId();
  }

  Future<void> pollClusterAndMetrics() async {
    final status = await apiService.getClusterStatus();
    final metrics = await apiService.getLatencyMetrics();
    if (status != null) clusterStatus = status;
    if (metrics != null) latencyMetrics = metrics;
    notifyListeners();
  }

  Future<void> generateSingleId() async {
    isGenerating = true;
    notifyListeners();

    final res = await apiService.getNextId();
    if (res != null) {
      currentId = res;
      qpsCounter++;
      pushFeed('Generated ID: ', res.strategy);

      // Auto-decode the current ID
      final parsed = await apiService.decodeId(res.id.toString());
      if (parsed != null) {
        parsedId = parsed;
      }
    }

    isGenerating = false;
    notifyListeners();
  }

  Future<void> generateBatch(int count) async {
    isGenerating = true;
    notifyListeners();

    final res = await apiService.getBatch(count);
    if (res != null && res.ids.isNotEmpty) {
      qpsCounter += res.count;
      pushFeed('Batch: generated  IDs in  µs', res.strategy);

      final lastId = res.ids.last;
      final parsed = await apiService.decodeId(lastId.toString());
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

    final res = await apiService.decodeId(cleanInput);
    if (res != null) {
      parsedId = res;
      pushFeed('Decoded ID: ', 'Node:  | Seq: ');
      notifyListeners();
    }
  }

  void toggleStream() {
    isStreaming = !isStreaming;
    if (isStreaming) {
      pushFeed('Started real-time streaming generator', 'Target: ~100 QPS');
      streamTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        generateSingleId();
      });
    } else {
      pushFeed('Stopped real-time streaming generator', 'Standby mode');
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
