import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/id_model.dart';
import 'package:frontend/models/cluster_model.dart';
import 'package:frontend/models/latency_model.dart';

void main() {
  test('IdResponse model deserializes JSON properly', () {
    final json = {
      'id': 2399340882693193728,
      'timestamp': 1788938241313,
      'dateTime': '2026-09-09T07:17:21.313Z',
      'nodeId': 0,
      'sequence': 42,
      'strategy': 'IN_MEMORY_SNOWFLAKE',
    };
    final res = IdResponse.fromJson(json);
    expect(res.id, 2399340882693193728);
    expect(res.nodeId, 0);
    expect(res.sequence, 42);
    expect(res.strategy, 'IN_MEMORY_SNOWFLAKE');
  });

  test('ClusterStatus model parses leader status accurately', () {
    final json = {
      'nodeId': 1,
      'leader': true,
      'zookeeperConnected': true,
      'redisConnected': true,
      'activeStrategy': 'AUTO',
      'epochMillis': 1780000000000,
      'registeredNodes': ['node-0', 'node-1'],
    };
    final status = ClusterStatus.fromJson(json);
    expect(status.nodeId, 1);
    expect(status.isLeader, true);
    expect(status.zookeeperConnected, true);
  });

  test('LatencyMetrics model parses percentiles properly', () {
    final json = {
      'totalGenerated': 1000,
      'p50Micros': 15.5,
      'p90Micros': 45.0,
      'p99Micros': 88.0,
      'p999Micros': 120.0,
      'maxMicros': 250.0,
      'meanMicros': 22.1,
    };
    final metrics = LatencyMetrics.fromJson(json);
    expect(metrics.totalGenerated, 1000);
    expect(metrics.p50Micros, 15.5);
    expect(metrics.p99Micros, 88.0);
  });
}
