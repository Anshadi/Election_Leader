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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.accent.withOpacity( 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TARGET: ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: state.selectedNodeIndex,
                        dropdownColor: AppColors.surfaceElevated,
                        isDense: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.accent),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Node 1 (:8001)')),
                          DropdownMenuItem(value: 1, child: Text('Node 2 (:8002)')),
                          DropdownMenuItem(value: 2, child: Text('Node 3 (:8003)')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.selectNode(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                label: 'QPS',
                value: state.currentQps.toString(),
                activeColor: AppColors.accent,
              ),
              _StatusPill(
                label: 'NODE_ID',
                value: '#' + nodeId.toString(),
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
            label + ': ',
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
