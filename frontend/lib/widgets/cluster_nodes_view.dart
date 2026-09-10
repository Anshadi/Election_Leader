import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cluster_model.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class ClusterNodesView extends StatelessWidget {
  const ClusterNodesView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final nodes = state.nodes;
    final onlineCount = nodes.where((n) => n.isOnline).length;
    final totalCount = nodes.length;
    final isBroadcasting = state.isBroadcasting;
    final isClusterStreaming = state.isClusterStreaming;

    NodeInstanceInfo? leaderNode;
    try {
      leaderNode = nodes.firstWhere((n) => n.isLeader && n.isOnline);
    } catch (_) {
      leaderNode = null;
    }

    return CleanPanel(
      title: 'MULTI-NODE CLUSTER TOPOLOGY & CONSENSUS',
      badge: 'APACHE ZOOKEEPER & CURATOR',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (onlineCount > 0 ? AppColors.green : AppColors.amber).withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: (onlineCount > 0 ? AppColors.green : AppColors.amber).withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: onlineCount > 0 ? AppColors.green : AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$onlineCount / $totalCount NODES ONLINE',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: onlineCount > 0 ? AppColors.green : AppColors.amber,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cluster Control & Summary Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, size: 16, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Text(
                      'ACTIVE LEADER: ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      leaderNode != null
                          ? '${leaderNode.label} (:${leaderNode.port})'
                          : (onlineCount > 0 ? 'Standalone / Acting Leader' : 'Awaiting Cluster...'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: leaderNode != null ? AppColors.accent : AppColors.amber,
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Stream All 3 Nodes Concurrently Button
                    InkWell(
                      onTap: () => state.toggleClusterStream(),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isClusterStreaming
                              ? AppColors.red.withOpacity(0.18)
                              : AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: isClusterStreaming
                                ? AppColors.red.withOpacity(0.5)
                                : AppColors.accent.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isClusterStreaming ? Icons.stop_circle_outlined : Icons.sensors_rounded,
                              size: 13,
                              color: isClusterStreaming ? AppColors.red : AppColors.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isClusterStreaming ? 'Stop Cluster Stream' : '⚡ Stream All Nodes',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isClusterStreaming ? AppColors.red : AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Fire All Nodes Concurrently
                    InkWell(
                      onTap: isBroadcasting ? null : () => state.broadcastGenerateAll(),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBroadcasting) ...[
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ] else ...[
                              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.accent),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              'Fire All Concurrently',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Scan
                    InkWell(
                      onTap: () => state.pollAllNodes(),
                      borderRadius: BorderRadius.circular(5),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.refresh_rounded, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Scan',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3-Node Matrix Cards Deck
          LayoutBuilder(
            builder: (context, constraints) {
              final isMultiCol = constraints.maxWidth > 750;

              if (isMultiCol) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < nodes.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _NodeDeckCard(
                          node: nodes[i],
                          index: i,
                          isSelected: state.selectedNodeIndex == i,
                          onSelect: () => state.selectNode(i),
                          onFire: () => state.generateSingleId(isManual: true, nodeIndex: i),
                          onToggleStream: () => state.toggleNodeStream(i),
                        ),
                      ),
                    ],
                  ],
                );
              } else {
                return Column(
                  children: [
                    for (int i = 0; i < nodes.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _NodeDeckCard(
                        node: nodes[i],
                        index: i,
                        isSelected: state.selectedNodeIndex == i,
                        onSelect: () => state.selectNode(i),
                        onFire: () => state.generateSingleId(isManual: true, nodeIndex: i),
                        onToggleStream: () => state.toggleNodeStream(i),
                      ),
                    ],
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 14),

          // Infrastructure Dependencies Health Pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _DepPill(
                label: 'ZooKeeper Quorum',
                port: ':2181',
                isConnected: nodes.any((n) => n.zkConnected),
                detail: 'Ephemeral Sequential 0..4095',
              ),
              _DepPill(
                label: 'Redis Lettuce Cache',
                port: ':6379',
                isConnected: nodes.any((n) => n.redisConnected),
                detail: 'Segment Leasing (20% prefetch)',
              ),
              const _DepPill(
                label: 'Prometheus Metrics',
                port: ':9090',
                isConnected: true,
                detail: 'Scrapes /actuator/prometheus',
              ),
              const _DepPill(
                label: 'Grafana Telemetry',
                port: ':3000',
                isConnected: true,
                detail: 'Live QPS & SLA Percentiles',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NodeDeckCard extends StatelessWidget {
  final NodeInstanceInfo node;
  final int index;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onFire;
  final VoidCallback onToggleStream;

  const _NodeDeckCard({
    required this.node,
    required this.index,
    required this.isSelected,
    required this.onSelect,
    required this.onFire,
    required this.onToggleStream,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = node.isOnline;
    final isLeader = node.isLeader && isOnline;
    final isStreaming = node.isStreaming;

    Color borderColor = AppColors.border;
    if (isSelected) {
      borderColor = AppColors.accent;
    } else if (isStreaming) {
      borderColor = AppColors.green;
    } else if (isLeader) {
      borderColor = AppColors.accent.withOpacity(0.4);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: borderColor,
          width: (isSelected || isStreaming) ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Node Label, Port, Target/Stream Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.green : AppColors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    node.label.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ':${node.port}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isStreaming)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(color: AppColors.green.withOpacity(0.4)),
                      ),
                      child: Text(
                        'STREAMING',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                    ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'TARGET',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Role Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: !isOnline
                  ? AppColors.red.withOpacity(0.1)
                  : isLeader
                      ? AppColors.accent.withOpacity(0.15)
                      : AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: !isOnline
                    ? AppColors.red.withOpacity(0.3)
                    : isLeader
                        ? AppColors.accent.withOpacity(0.4)
                        : AppColors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLeader) ...[
                  const Icon(Icons.shield_rounded, size: 12, color: AppColors.accent),
                  const SizedBox(width: 5),
                ],
                Text(
                  !isOnline
                      ? 'OFFLINE / UNREACHABLE'
                      : isLeader
                          ? 'LEADER (LeaderLatch Holder)'
                          : 'STANDBY (Candidate in Quorum)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: !isOnline
                        ? AppColors.red
                        : isLeader
                            ? AppColors.accent
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Allocated Range & Segment Health Box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LEASED SEGMENT RANGE',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '[${node.segmentMin} .. ${node.segmentMax}]',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: node.segmentUsageRatio > 0 ? node.segmentUsageRatio : 0.05,
                    minHeight: 4,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      node.segmentUsageRatio > 0.8 ? AppColors.accent : AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Double-Buffered Leaf Prefetch @ 20%',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      '${(node.segmentUsageRatio * 100).toStringAsFixed(0)}% Used',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Node Parameter Matrix
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _ParamRow(
                  label: 'ZK Node ID',
                  value: isOnline ? '#${node.nodeId}' : '---',
                  valueColor: AppColors.accent,
                ),
                const SizedBox(height: 3),
                _ParamRow(
                  label: 'Strategy',
                  value: isOnline ? node.strategy : '---',
                ),
                const SizedBox(height: 3),
                _ParamRow(
                  label: 'Ping SLA',
                  value: isOnline ? '${node.pingMs.toStringAsFixed(1)} ms' : 'N/A',
                  valueColor: isOnline ? AppColors.green : AppColors.textMuted,
                ),
                const SizedBox(height: 3),
                _ParamRow(
                  label: 'ZK & Redis',
                  value: isOnline
                      ? '${node.zkConnected ? "ZK: OK" : "ZK: NO"} • ${node.redisConnected ? "Redis: OK" : "Redis: NO"}'
                      : 'Disconnected',
                  valueColor: (node.zkConnected && node.redisConnected) ? AppColors.green : AppColors.amber,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Last Generated Sequence Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LAST ALLOCATED ID',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Text(
                      node.generatedCount > 0 ? '${node.generatedCount} Total IDs' : '0 Total IDs',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                SelectableText(
                  node.lastGeneratedId != null
                      ? '${node.lastGeneratedId} (Seq: #${node.lastSequence ?? 0})'
                      : 'No ID generated yet',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: node.lastGeneratedId != null ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons: Fire, Stream, Set Target
          Row(
            children: [
              // Fire 1 ID
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: (isOnline && !node.isGenerating) ? onFire : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isOnline ? AppColors.surfaceElevated : AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isOnline ? AppColors.border : AppColors.border.withOpacity(0.5)),
                    ),
                    child: Center(
                      child: node.isGenerating
                          ? const SizedBox(
                              width: 11,
                              height: 11,
                              child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent)),
                            )
                          : Text(
                              '⚡ Fire',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: isOnline ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Individual Stream Toggle
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: isOnline ? onToggleStream : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isStreaming
                          ? AppColors.red.withOpacity(0.18)
                          : isOnline
                              ? AppColors.surfaceElevated
                              : AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isStreaming
                            ? AppColors.red.withOpacity(0.5)
                            : isOnline
                                ? AppColors.border
                                : AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isStreaming ? '⏹ Stop' : 'Stream',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isStreaming
                              ? AppColors.red
                              : isOnline
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Set Target
              Expanded(
                flex: 4,
                child: InkWell(
                  onTap: onSelect,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: isSelected ? AppColors.accent : AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        isSelected ? '✓ Target' : 'Set Target',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
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

class _ParamRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ParamRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _DepPill extends StatelessWidget {
  final String label;
  final String port;
  final bool isConnected;
  final String detail;

  const _DepPill({
    required this.label,
    required this.port,
    required this.isConnected,
    required this.detail,
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
            '$label $port',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($detail)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
