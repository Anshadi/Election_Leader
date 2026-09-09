import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';

class ElectionLeaderApiService {
  final String baseUrl;

  ElectionLeaderApiService({this.baseUrl = 'http://localhost:8001'});

  Future<IdResponse?> getNextId() async {
    try {
      final response = await http
          .get(Uri.parse('/api/v1/id/next'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return IdResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<BatchResponse?> getBatch(int count) async {
    try {
      final response = await http
          .get(Uri.parse('/api/v1/id/batch?count='))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return BatchResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ParsedId?> decodeId(String id) async {
    try {
      final response = await http
          .get(Uri.parse('/api/v1/id/decode/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return ParsedId.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ClusterStatus?> getClusterStatus() async {
    try {
      final response = await http
          .get(Uri.parse('/api/v1/cluster/status'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return ClusterStatus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<LatencyMetrics?> getLatencyMetrics() async {
    try {
      final response = await http
          .get(Uri.parse('/api/v1/metrics/latency'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return LatencyMetrics.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }
}
