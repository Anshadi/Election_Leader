import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class ClusterTopologyCard extends StatelessWidget {
  const ClusterTopologyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final cluster = state.clusterStatus;
    final isLeader = cluster?.isLeader ?? true;
    final nodeId = cluster?.nodeId ?? 0;
    final zkConnected = cluster?.zookeeperConnected ?? false;
    final redisConnected = cluster?.redisConnected ?? false;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Cluster Topology & Consensus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Curator LeaderLatch',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Visual Node Cluster Grid
          Row(
            children: [
              // Node 1 (Current instance / Leader)
              Expanded(
                child: _NodeBox(
                  nodeName: 'Node #$nodeId',
                  role: isLeader ? '👑 Primary Leader' : '🛡️ Worker Node',
                  status: 'Active (Current)',
                  isLeader: isLeader,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 8),

              // Standby Node 2
              Expanded(
                child: _NodeBox(
                  nodeName: 'Node #1',
                  role: !isLeader ? '👑 Primary Leader' : '🛡️ Standby Worker',
                  status: zkConnected ? 'Active' : 'Standby',
                  isLeader: !isLeader,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 8),

              // Standby Node 3
              Expanded(
                child: _NodeBox(
                  nodeName: 'Node #2',
                  role: '🛡️ Standby Worker',
                  status: zkConnected ? 'Active' : 'Standby',
                  isLeader: false,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Infrastructure Dependencies Health
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                _DependencyItem(
                  name: 'ZooKeeper Coordinator',
                  port: ':2181',
                  isHealthy: zkConnected,
                ),
                _DependencyItem(
                  name: 'Redis Reactive Store',
                  port: ':6379',
                  isHealthy: redisConnected,
                ),
                const _DependencyItem(
                  name: 'Actuator Prometheus',
                  port: ':8001/actuator',
                  isHealthy: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NodeBox extends StatelessWidget {
  final String nodeName;
  final String role;
  final String status;
  final bool isLeader;
  final bool isPrimary;

  const _NodeBox({
    required this.nodeName,
    required this.role,
    required this.status,
    required this.isLeader,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isLeader
        ? AppColors.amber.withOpacity(0.5)
        : (isPrimary ? AppColors.violet.withOpacity(0.4) : AppColors.borderSubtle);
    final bgColor = isLeader
        ? AppColors.amber.withOpacity(0.1)
        : (isPrimary ? AppColors.violet.withOpacity(0.08) : Colors.black.withOpacity(0.3));

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: isLeader ? 1.5 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  nodeName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isLeader ? AppColors.amber : AppColors.textPrimary,
                  ),
                ),
              ),
              if (isLeader)
                const Text('⭐', style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            role,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: isLeader ? AppColors.amber : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DependencyItem extends StatelessWidget {
  final String name;
  final String port;
  final bool isHealthy;

  const _DependencyItem({
    required this.name,
    required this.port,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isHealthy ? AppColors.emerald : AppColors.amber,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isHealthy ? AppColors.emerald : AppColors.amber).withOpacity(0.5),
                blurRadius: 6,
              )
            ],
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              isHealthy ? 'Connected ($port)' : 'Standalone Fallback',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
