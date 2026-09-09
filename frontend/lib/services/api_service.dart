import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/id_model.dart';
import '../models/cluster_model.dart';
import '../models/latency_model.dart';

class ElectionLeaderApiService {
  String baseUrl;

  ElectionLeaderApiService({this.baseUrl = 'http://localhost:8001'});

  Future<IdResponse?> getNextId({String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? baseUrl;
    try {
      final response = await http
          .get(Uri.parse('\/api/v1/id/next'))
          .timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        return IdResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<BatchResponse?> getBatch(int count, {String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? baseUrl;
    try {
      final response = await http
          .get(Uri.parse('\/api/v1/id/batch?count='))
          .timeout(const Duration(milliseconds: 2500));
      if (response.statusCode == 200) {
        return BatchResponse.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ParsedId?> decodeId(String id, {String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? baseUrl;
    try {
      final response = await http
          .get(Uri.parse('\/api/v1/id/decode/'))
          .timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        return ParsedId.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<ClusterStatus?> getClusterStatus({String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? baseUrl;
    try {
      final response = await http
          .get(Uri.parse('\/api/v1/cluster/status'))
          .timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        return ClusterStatus.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  Future<LatencyMetrics?> getLatencyMetrics({String? overrideUrl}) async {
    final targetUrl = overrideUrl ?? baseUrl;
    try {
      final response = await http
          .get(Uri.parse('\/api/v1/metrics/latency'))
          .timeout(const Duration(milliseconds: 1500));
      if (response.statusCode == 200) {
        return LatencyMetrics.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }
}
