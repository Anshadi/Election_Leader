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
      title: 'ACTIVITY LOG / SSE FEED',
      badge: 'REACTIVE STREAM',
      child: Container(
        height: 180,
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
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isFirst = index == 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SelectableText(
                            '> ${item['title']}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 11,
                              fontWeight: isFirst ? FontWeight.w700 : FontWeight.w500,
                              color: isFirst ? AppColors.accent : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Text(
                          item['subtitle'] ?? '',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            color: AppColors.textMuted,
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
