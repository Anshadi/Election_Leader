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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          // Brand info
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.violet, AppColors.cyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withOpacity(0.4),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('⚡', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ElectionLeader Control Center',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Distributed ID Generator • ZooKeeper Leader Latch • Redis Segment Prefetch',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Status Badges
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // QPS Counter
              _StatusBadge(
                label: '${state.currentQps} QPS',
                icon: Icons.speed,
                color: AppColors.cyanLight,
                bgColor: AppColors.cyan.withOpacity(0.15),
                borderColor: AppColors.cyan.withOpacity(0.4),
              ),

              // Leader Badge
              _StatusBadge(
                label: isLeader ? '👑 CLUSTER LEADER' : '🛡️ STANDBY NODE',
                icon: isLeader ? Icons.star : Icons.shield_outlined,
                color: isLeader ? AppColors.amber : AppColors.textSecondary,
                bgColor: isLeader ? AppColors.amber.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                borderColor: isLeader ? AppColors.amber.withOpacity(0.4) : AppColors.borderSubtle,
                pulse: isLeader,
              ),

              // Node Badge
              _StatusBadge(
                label: 'Node #$nodeId',
                icon: Icons.developer_board,
                color: AppColors.violet,
                bgColor: AppColors.violet.withOpacity(0.15),
                borderColor: AppColors.violet.withOpacity(0.4),
              ),

              // Strategy Badge
              _StatusBadge(
                label: strategy,
                icon: Icons.auto_awesome,
                color: AppColors.emeraldLight,
                bgColor: AppColors.emerald.withOpacity(0.15),
                borderColor: AppColors.emerald.withOpacity(0.4),
              ),

              // ZK Badge
              _StatusBadge(
                label: zkConnected ? 'ZK: Connected' : 'ZK: Standalone',
                icon: Icons.hub,
                color: zkConnected ? AppColors.emeraldLight : AppColors.textMuted,
                bgColor: zkConnected ? AppColors.emerald.withOpacity(0.15) : Colors.white.withOpacity(0.03),
                borderColor: zkConnected ? AppColors.emerald.withOpacity(0.4) : AppColors.borderSubtle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final bool pulse;

  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
