import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class TelemetryView extends StatelessWidget {
  const TelemetryView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final metrics = state.latencyMetrics;

    final p50 = metrics?.p50Micros ?? 0.0;
    final p90 = metrics?.p90Micros ?? 0.0;
    final p99 = metrics?.p99Micros ?? 0.0;
    final p999 = metrics?.p999Micros ?? 0.0;
    final total = metrics?.totalGenerated ?? 0;
    final mean = metrics?.meanMicros ?? 0.0;
    final max = metrics?.maxMicros ?? 0.0;

    return CleanPanel(
      title: 'LATENCY SLA & METRICS',
      badge: 'HDRHISTOGRAM',
      trailing: Text(
        'TOTAL: \ IDs',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PercentileRow(
            label: 'P50 (MEDIAN)',
            value: '\ µs',
            ratio: (p50 / 1000.0).clamp(0.05, 1.0),
            color: AppColors.green,
          ),
          const SizedBox(height: 8),
          _PercentileRow(
            label: 'P90 SLA',
            value: '\ µs',
            ratio: (p90 / 2000.0).clamp(0.1, 1.0),
            color: AppColors.blue,
          ),
          const SizedBox(height: 8),
          _PercentileRow(
            label: 'P99 SLA',
            value: '\ µs',
            ratio: (p99 / 5000.0).clamp(0.2, 1.0),
            color: AppColors.accent,
          ),
          const SizedBox(height: 8),
          _PercentileRow(
            label: 'P99.9 MAX',
            value: '\ µs',
            ratio: (p999 / 10000.0).clamp(0.3, 1.0),
            color: AppColors.amber,
          ),
          const SizedBox(height: 14),

          // Aggregate Summary Strip (Wrap to avoid any overflow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              alignment: WrapAlignment.spaceBetween,
              children: [
                _StatItem(label: 'MEAN LATENCY', value: '\ µs'),
                _StatItem(label: 'MAX SPIKE', value: '\ µs'),
                const _StatItem(label: 'STATUS', value: 'ONLINE (:8001)'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentileRow extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;

  const _PercentileRow({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 3.5,
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
