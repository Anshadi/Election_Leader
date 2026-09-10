import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';

class ElectionLeaderApiService {
  Future<IdResponse?> getNextId({String baseUrl = 'http://localhost:8001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/id/next');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return IdResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<BatchResponse?> getBatch(int count, {String baseUrl = 'http://localhost:8001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/id/batch?count=$count');
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return BatchResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ParsedId?> decodeId(String id, {String baseUrl = 'http://localhost:8001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/id/decode/$id');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return ParsedId.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ClusterStatus?> getClusterStatus({String baseUrl = 'http://localhost:8001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/cluster/status');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return ClusterStatus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<LatencyMetrics?> getLatencyMetrics({String baseUrl = 'http://localhost:8001'}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/v1/metrics/latency');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return LatencyMetrics.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }
}
