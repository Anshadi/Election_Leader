import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';

class HeaderBar extends StatelessWidget {
  const HeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final cluster = state.clusterStatus;
    final isLeader = cluster?.isLeader ?? true;
    final nodeId = cluster?.nodeId ?? 0;
    final strategy = cluster?.activeStrategy ?? 'AUTO';
    final zkConnected = cluster?.zookeeperConnected ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Monospace System Identifier
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ELECTION_LEADER',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  'v1.0-RELEASE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Right: Telemetry & Cluster State Pills (No emojis, crisp technical layout)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusPill(
                label: 'QPS',
                value: '${state.currentQps}',
                activeColor: AppColors.accent,
              ),
              _StatusPill(
                label: 'NODE',
                value: '#$nodeId',
                activeColor: AppColors.blue,
              ),
              _StatusPill(
                label: 'ROLE',
                value: isLeader ? 'LEADER' : 'STANDBY',
                activeColor: isLeader ? AppColors.green : AppColors.textSecondary,
              ),
              _StatusPill(
                label: 'STRATEGY',
                value: strategy,
                activeColor: AppColors.textPrimary,
              ),
              _StatusPill(
                label: 'ZK',
                value: zkConnected ? 'ONLINE' : 'STANDALONE',
                activeColor: zkConnected ? AppColors.green : AppColors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  final Color activeColor;

  const _StatusPill({
    required this.label,
    required this.value,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: activeColor,
            ),
          ),
        ],
      ),
    );
  }
}
