import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class ClusterNodesView extends StatelessWidget {
  const ClusterNodesView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final cluster = state.clusterStatus;
    final isLeader = cluster?.isLeader ?? true;
    final nodeId = cluster?.nodeId ?? 0;
    final zkConnected = cluster?.zookeeperConnected ?? false;
    final redisConnected = cluster?.redisConnected ?? false;

    return CleanPanel(
      title: 'CLUSTER TOPOLOGY & CONSENSUS',
      badge: 'ZOOKEEPER LEADER LATCH',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nodes Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _ColHeader('INSTANCE')),
                Expanded(flex: 3, child: _ColHeader('ROLE')),
                Expanded(flex: 4, child: _ColHeader('CONSENSUS STATE')),
                Expanded(flex: 2, child: _ColHeader('HEALTH')),
              ],
            ),
          ),

          // Node Rows
          _NodeTableRow(
            instance: 'node-' + nodeId.toString() + ' (Current)',
            role: isLeader ? 'LEADER (PRIMARY)' : 'WORKER (STANDBY)',
            consensusState: isLeader ? 'Holding LeaderLatch' : 'Standby Candidate',
            isLeader: isLeader,
            isHealthy: true,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _NodeTableRow(
            instance: 'node-1',
            role: !isLeader ? 'LEADER (PRIMARY)' : 'WORKER (STANDBY)',
            consensusState: zkConnected ? 'Standby Candidate' : 'Local Standalone',
            isLeader: !isLeader,
            isHealthy: zkConnected,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _NodeTableRow(
            instance: 'node-2',
            role: 'WORKER (STANDBY)',
            consensusState: zkConnected ? 'Standby Candidate' : 'Local Standalone',
            isLeader: false,
            isHealthy: zkConnected,
          ),
          const SizedBox(height: 14),

          // Infrastructure Dependencies Health
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DepPill(label: 'ZooKeeper Quorum', port: ':2181', isConnected: zkConnected),
              _DepPill(label: 'Redis Lettuce Cache', port: ':6379', isConnected: redisConnected),
              const _DepPill(label: 'Prometheus Metrics', port: ':9090', isConnected: true),
              const _DepPill(label: 'Grafana Telemetry', port: ':3000', isConnected: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  final String text;
  const _ColHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _NodeTableRow extends StatelessWidget {
  final String instance;
  final String role;
  final String consensusState;
  final bool isLeader;
  final bool isHealthy;

  const _NodeTableRow({
    required this.instance,
    required this.role,
    required this.consensusState,
    required this.isLeader,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              instance,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isLeader ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLeader) ...[
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    role,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                      color: isLeader ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              consensusState,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isHealthy ? AppColors.green : AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    isHealthy ? 'ACTIVE' : 'OFFLINE',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: isHealthy ? AppColors.green : AppColors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DepPill extends StatelessWidget {
  final String label;
  final String port;
  final bool isConnected;

  const _DepPill({
    required this.label,
    required this.port,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.green : AppColors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label + ' ' + port,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
