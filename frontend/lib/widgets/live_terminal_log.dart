import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class LiveTerminalLog extends StatelessWidget {
  const LiveTerminalLog({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final items = state.filteredFeedItems;
    final filter = state.selectedLogFilter;

    return CleanPanel(
      title: 'EVENT STREAM / CLI LOG',
      badge: 'REACTIVE SSE STREAM',
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterTab(
            label: 'ALL',
            isSelected: filter == 'ALL',
            onTap: () => state.setLogFilter('ALL'),
          ),
          ...state.nodes.map((n) => _FilterTab(
            label: n.label.toUpperCase(),
            isSelected: filter == n.id,
            onTap: () => state.setLogFilter(n.id),
          )),
          const SizedBox(width: 4),
          Text(
            ' EVENTS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
      child: Container(
        height: 175,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: items.isEmpty
            ? Center(
                child: Text(
                  'No activity recorded for this filter. Generate or stream IDs above.',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isFirst = index == 0;
                  final nodeTag = item['nodeId'] ?? 'ALL';
                  final time = item['time'] ?? '';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (time.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text(
                              time,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        if (nodeTag != 'ALL')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              nodeTag.toUpperCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        Text(
                          '> ',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isFirst ? AppColors.accent : AppColors.textMuted,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item['title'] ?? '',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10.5,
                              fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                              color: isFirst ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (item['subtitle'] != null && item['subtitle']!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(
                              item['subtitle']!,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9.5,
                                color: isFirst ? AppColors.accent : AppColors.textMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTab({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
