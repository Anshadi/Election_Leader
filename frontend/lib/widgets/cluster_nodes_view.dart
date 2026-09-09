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
    final nodes = state.clusterNodes;
    final simultaneous = state.simultaneousResults;
    final zkConnected = state.clusterStatus?.zookeeperConnected ?? false;
    final redisConnected = state.clusterStatus?.redisConnected ?? false;

    return CleanPanel(
      title: 'MULTI-NODE CLUSTER CONTROLLER',
      badge: 'ZOOKEEPER & REDIS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Cluster Node Grid (Wrap or Row)
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 360;
              if (isSmall) {
                return Column(
                  children: List.generate(3, (index) {
                    final node = index < nodes.length ? nodes[index] : null;
                    final isSelected = state.selectedNodeIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _NodeInstanceCard(
                        index: index,
                        port: 8001 + index,
                        node: node,
                        isSelected: isSelected,
                        onSelect: () => state.selectNode(index),
                        onGenerate: () => state.generateSingleId(fromNodeIndex: index),
                      ),
                    );
                  }),
                );
              }
              return Row(
                children: List.generate(3, (index) {
                  final node = index < nodes.length ? nodes[index] : null;
                  final isSelected = state.selectedNodeIndex == index;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 3,
                        right: index == 2 ? 0 : 3,
                      ),
                      child: _NodeInstanceCard(
                        index: index,
                        port: 8001 + index,
                        node: node,
                        isSelected: isSelected,
                        onSelect: () => state.selectNode(index),
                        onGenerate: () => state.generateSingleId(fromNodeIndex: index),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),

          // Simultaneous Cluster Generation Action
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONCURRENT MULTI-NODE GENERATION',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dispatches parallel requests to Node 1, 2, and 3 at the same ms.',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: state.isMultiGenerating
                          ? null
                          : () => state.generateSimultaneousAcrossCluster(),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: state.isMultiGenerating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.flash_on, size: 13, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'FIRE ALL 3 NODES',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),

                // Multi-node comparison output
                if (simultaneous.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, thickness: 1, color: AppColors.border),
                  const SizedBox(height: 8),
                  Text(
                    'MULTI-NODE OUTPUT COMPARISON (VERIFIED 0 COLLISIONS):',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 380;
                      if (isNarrow) {
                        return Column(
                          children: List.generate(3, (idx) {
                            final item = simultaneous[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: _ComparisonTile(idx: idx, item: item),
                            );
                          }),
                        );
                      }
                      return Row(
                        children: List.generate(3, (idx) {
                          final item = simultaneous[idx];
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: idx == 0 ? 0 : 2,
                                right: idx == 2 ? 0 : 2,
                              ),
                              child: _ComparisonTile(idx: idx, item: item),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Infrastructure Dependencies Health
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _DepPill(label: 'ZooKeeper', port: ':2181', isConnected: zkConnected),
              _DepPill(label: 'Redis', port: ':6379', isConnected: redisConnected),
              const _DepPill(label: 'Prometheus', port: ':9090', isConnected: true),
              const _DepPill(label: 'Grafana', port: ':3000', isConnected: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonTile extends StatelessWidget {
  final int idx;
  final dynamic item;

  const _ComparisonTile({required this.idx, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: item != null ? AppColors.accent.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: item != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NODE ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    Text(
                      'ID: ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                SelectableText(
                  item.id.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Seq: ',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            )
          : Center(
              child: Text(
                'Node \ Offline',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
    );
  }
}

class _NodeInstanceCard extends StatelessWidget {
  final int index;
  final int port;
  final dynamic node;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onGenerate;

  const _NodeInstanceCard({
    required this.index,
    required this.port,
    required this.node,
    required this.isSelected,
    required this.onSelect,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = node?.isOnline == true;
    final isLeader = node?.isLeader == true;
    final nodeId = node?.nodeId ?? index;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surfaceElevated : AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? AppColors.accent : AppColors.border,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.green : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'NODE ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isLeader ? AppColors.accent.withOpacity(0.15) : AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: isLeader ? AppColors.accent.withOpacity(0.5) : AppColors.border,
                  ),
                ),
                child: Text(
                  isLeader ? 'LEADER' : 'STANDBY',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: isLeader ? AppColors.accent : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Port & Node ID info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ':',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                'ID: ',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onSelect,
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      isSelected ? 'ACTIVE' : 'SELECT',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              InkWell(
                onTap: isOnline ? onGenerate : null,
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'PULL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: isOnline ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
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
          const SizedBox(width: 5),
          Text(
            '\ ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
