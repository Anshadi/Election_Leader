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
                Expanded(flex: 2, child: _ColHeader('INSTANCE')),
                Expanded(flex: 3, child: _ColHeader('ROLE')),
                Expanded(flex: 3, child: _ColHeader('CONSENSUS STATE')),
                Expanded(flex: 2, child: _ColHeader('HEALTH')),
              ],
            ),
          ),

          // Node Rows
          _NodeTableRow(
            instance: 'node-$nodeId (Current)',
            role: isLeader ? 'LEADER (PRIMARY)' : 'WORKER',
            consensusState: isLeader ? 'Holding LeaderLatch' : 'Standby Latch',
            isLeader: isLeader,
            isHealthy: true,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _NodeTableRow(
            instance: 'node-1',
            role: !isLeader ? 'LEADER (PRIMARY)' : 'WORKER (STANDBY)',
            consensusState: 'Standby Candidate',
            isLeader: !isLeader,
            isHealthy: zkConnected,
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          const _NodeTableRow(
            instance: 'node-2',
            role: 'WORKER (STANDBY)',
            consensusState: 'Standby Candidate',
            isLeader: false,
            isHealthy: false,
          ),
          const SizedBox(height: 16),

          // Infrastructure Dependencies Health
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DepPill(label: 'ZooKeeper Quorum', port: ':2181', isConnected: zkConnected),
              _DepPill(label: 'Redis Lettuce Cache', port: ':6379', isConnected: redisConnected),
              const _DepPill(label: 'Prometheus Actuator', port: ':8001', isConnected: true),
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
        fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              instance,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isLeader ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (isLeader) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isLeader ? FontWeight.w700 : FontWeight.w500,
                    color: isLeader ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              consensusState,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isHealthy ? AppColors.green : AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isHealthy ? 'ACTIVE' : 'STANDALONE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isHealthy ? AppColors.green : AppColors.amber,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? AppColors.green : AppColors.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label $port',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
