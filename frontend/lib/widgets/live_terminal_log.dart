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
    final items = state.feedItems;

    return CleanPanel(
      title: 'EVENT STREAM / CLI LOG',
      badge: 'REACTIVE STREAM',
      trailing: Text(
        ' EVENTS',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
        ),
      ),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: items.isEmpty
            ? Center(
                child: Text(
                  'No activity recorded. Generate IDs above.',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
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
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
