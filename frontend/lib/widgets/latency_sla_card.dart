import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class LatencySlaCard extends StatelessWidget {
  const LatencySlaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final metrics = state.latencyMetrics;

    final p50 = metrics?.p50Micros ?? 0.0;
    final p90 = metrics?.p90Micros ?? 0.0;
    final p99 = metrics?.p99Micros ?? 0.0;
    final p999 = metrics?.p999Micros ?? 0.0;
    final total = metrics?.totalGenerated ?? 0;
    final max = metrics?.maxMicros ?? 0.0;
    final mean = metrics?.meanMicros ?? 0.0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📊', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Latency SLA (HdrHistogram)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Values in Microseconds (µs)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Percentile Gauges
          Row(
            children: [
              Expanded(child: _PercentileBox(label: 'P50 (Median)', value: '${p50.toStringAsFixed(0)} µs', color: AppColors.emeraldLight)),
              const SizedBox(width: 8),
              Expanded(child: _PercentileBox(label: 'P90 SLA', value: '${p90.toStringAsFixed(0)} µs', color: AppColors.cyanLight)),
              const SizedBox(width: 8),
              Expanded(child: _PercentileBox(label: 'P99 SLA', value: '${p99.toStringAsFixed(0)} µs', color: AppColors.violet)),
              const SizedBox(width: 8),
              Expanded(child: _PercentileBox(label: 'P99.9 Max', value: '${p999.toStringAsFixed(0)} µs', color: AppColors.amber)),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Stats Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryText(label: 'Total Generated', value: total.toString()),
                _SummaryText(label: 'Mean Latency', value: '${mean.toStringAsFixed(1)} µs'),
                _SummaryText(label: 'Max Spike', value: '${max.toStringAsFixed(0)} µs'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentileBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PercentileBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryText extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
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
