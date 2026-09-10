import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class IdGeneratorView extends StatelessWidget {
  const IdGeneratorView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final id = state.currentId;
    final idStr = id != null ? id.id.toString() : '---';
    final isStreaming = state.isStreaming;
    final activeNode = state.activeNode;

    String timeStr = '--:--:--';
    if (id != null && id.dateTime.isNotEmpty) {
      final parts = id.dateTime.split('T');
      if (parts.length > 1) {
        timeStr = parts[1].replaceAll('Z', '');
      } else {
        timeStr = id.dateTime;
      }
    }

    return CleanPanel(
      title: 'PRIMARY ID GENERATOR',
      badge: '64-BIT SORTABLE',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: (activeNode.isOnline ? AppColors.green : AppColors.amber).withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: (activeNode.isOnline ? AppColors.green : AppColors.amber).withOpacity(0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: activeNode.isOnline ? AppColors.green : AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '${activeNode.label.toUpperCase()} (:${activeNode.port})',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: activeNode.isOnline ? AppColors.green : AppColors.amber,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large ID Output Field
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALLOCATED SEQUENCE ID',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        idStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                  tooltip: 'Copy ID',
                  splashRadius: 18,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: idStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('ID $idStr copied to clipboard', style: GoogleFonts.jetBrainsMono(fontSize: 12)),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.surfaceElevated,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Controls Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Generate Next',
                isPrimary: true,
                onTap: () => state.generateSingleId(isManual: true),
              ),
              _ActionButton(
                label: 'Batch 100',
                onTap: () => state.generateBatch(100),
              ),
              _ActionButton(
                label: 'Batch 1,000',
                onTap: () => state.generateBatch(1000),
              ),
              _ActionButton(
                label: isStreaming ? 'Stream [ACTIVE]' : 'Stream [OFF]',
                isActiveToggle: isStreaming,
                onTap: () => state.toggleStream(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Technical Parameter Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _ParamColumn(
                  label: 'TIMESTAMP (UTC)',
                  value: timeStr,
                ),
                _ParamColumn(
                  label: 'ZK NODE ID',
                  value: id != null ? '#${id.nodeId}' : '#${activeNode.nodeId}',
                ),
                _ParamColumn(
                  label: 'SEQUENCE',
                  value: id != null ? id.sequence.toString() : '0',
                ),
                _ParamColumn(
                  label: 'STRATEGY',
                  value: id?.strategy ?? activeNode.strategy,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final bool isActiveToggle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.isPrimary = false,
    this.isActiveToggle = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg = AppColors.surfaceElevated;
    Color fg = AppColors.textPrimary;
    Color border = AppColors.border;

    if (isPrimary) {
      bg = AppColors.accent;
      fg = Colors.white;
      border = AppColors.accent;
    } else if (isActiveToggle) {
      bg = AppColors.red.withOpacity(0.15);
      fg = AppColors.red;
      border = AppColors.red.withOpacity(0.4);
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: border),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _ParamColumn extends StatelessWidget {
  final String label;
  final String value;

  const _ParamColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
