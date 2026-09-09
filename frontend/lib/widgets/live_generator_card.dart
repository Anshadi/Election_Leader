import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class LiveGeneratorCard extends StatelessWidget {
  const LiveGeneratorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final id = state.currentId;
    final idString = id != null ? id.id.toString() : '---';
    final isStreaming = state.isStreaming;

    return GlassCard(
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🚀', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Live ID Generator',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.emerald.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ready to Lease',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emeraldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons Row
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => state.generateSingleId(),
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('Generate Single'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 6,
                  shadowColor: AppColors.violet.withOpacity(0.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => state.generateBatch(100),
                icon: const Icon(Icons.layers_outlined, size: 16),
                label: const Text('Batch (100)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyanLight,
                  side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => state.generateBatch(1000),
                icon: const Icon(Icons.all_inclusive, size: 16),
                label: const Text('Batch (1,000)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.emeraldLight,
                  side: BorderSide(color: AppColors.emerald.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => state.toggleStream(),
                icon: Icon(isStreaming ? Icons.stop : Icons.play_arrow, size: 16),
                label: Text(isStreaming ? 'Stop Stream' : 'Live Stream'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStreaming ? AppColors.red.withOpacity(0.2) : Colors.white.withOpacity(0.06),
                  foregroundColor: isStreaming ? AppColors.red : AppColors.textPrimary,
                  side: BorderSide(
                    color: isStreaming ? AppColors.red.withOpacity(0.6) : AppColors.borderSubtle,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Massive Hero ID Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CURRENT PACKED 64-BIT ID',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.textMuted,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondary),
                      tooltip: 'Copy ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: idString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ID copied to clipboard!'),
                            duration: Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  idString,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.cyanLight,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 14),

                // Meta values grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _MetaItem(
                      label: 'UTC TIMESTAMP',
                      value: id != null && id.dateTime.isNotEmpty
                          ? id.dateTime.split('T')[1].replaceAll('Z', '')
                          : '--:--:--',
                      color: AppColors.cyanLight,
                    ),
                    _MetaItem(
                      label: 'NODE ID',
                      value: id != null ? '#${id.nodeId}' : '#0',
                      color: AppColors.violet,
                    ),
                    _MetaItem(
                      label: 'SEQUENCE',
                      value: id != null ? '${id.sequence}' : '0',
                      color: AppColors.emeraldLight,
                    ),
                    _MetaItem(
                      label: 'STRATEGY',
                      value: id?.strategy ?? 'AUTO',
                      color: AppColors.amber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetaItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
