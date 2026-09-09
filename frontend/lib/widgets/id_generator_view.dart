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

    return CleanPanel(
      title: 'PRIMARY ID GENERATOR',
      badge: '64-BIT SORTABLE',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.green.withOpacity(0.3)),
        ),
        child: Text(
          'HEALTHY',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.green,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large ID Output Field
          Container(
            padding: const EdgeInsets.all(16),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        idStr,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.0,
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

          // Action Controls Row (Tactile buttons, no glowing emojis)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                label: 'Generate Next',
                isPrimary: true,
                onTap: () => state.generateSingleId(),
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
          const SizedBox(height: 18),

          // Technical Parameter Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ParamColumn(
                  label: 'TIMESTAMP (UTC)',
                  value: id != null && id.dateTime.isNotEmpty
                      ? id.dateTime.split('T')[1].replaceAll('Z', '')
                      : '--:--:--',
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                _ParamColumn(
                  label: 'NODE ID',
                  value: id != null ? '#${id.nodeId}' : '#0',
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                _ParamColumn(
                  label: 'SEQUENCE',
                  value: id != null ? '${id.sequence}' : '0',
                ),
                Container(width: 1, height: 26, color: AppColors.border),
                _ParamColumn(
                  label: 'STRATEGY',
                  value: id?.strategy ?? 'AUTO',
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
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
