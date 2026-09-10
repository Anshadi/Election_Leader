import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/dashboard_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/header_bar.dart';
import 'widgets/id_generator_view.dart';
import 'widgets/bit_memory_map.dart';
import 'widgets/cluster_nodes_view.dart';
import 'widgets/telemetry_view.dart';
import 'widgets/live_terminal_log.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const ElectionLeaderApp(),
    ),
  );
}

class ElectionLeaderApp extends StatelessWidget {
  const ElectionLeaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ElectionLeader Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 1050;
            final padding = EdgeInsets.symmetric(
              horizontal: isWide ? 28 : 16,
              vertical: 20,
            );

            return SingleChildScrollView(
              padding: padding,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Minimalist Header Bar
                      const HeaderBar(),
                      const SizedBox(height: 18),

                      // Balanced Two-Column Grid Layout
                      if (isWide)
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Main Column: Generator, Memory Map, Latency SLA & Live SSE Feed
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  IdGeneratorView(),
                                  SizedBox(height: 18),
                                  BitMemoryMap(),
                                  SizedBox(height: 18),
                                  TelemetryView(),
                                  SizedBox(height: 18),
                                  LiveTerminalLog(),
                                ],
                              ),
                            ),
                            SizedBox(width: 18),

                            // Right Column: Multi-Node Topology & Consensus Matrix Deck
                            Expanded(
                              flex: 6,
                              child: Column(
                                children: [
                                  ClusterNodesView(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        const IdGeneratorView(),
                        const SizedBox(height: 14),
                        const BitMemoryMap(),
                        const SizedBox(height: 14),
                        const TelemetryView(),
                        const SizedBox(height: 14),
                        const LiveTerminalLog(),
                        const SizedBox(height: 14),
                        const ClusterNodesView(),
                      ],
                      const SizedBox(height: 24),

                      // Clean Engineering Footer
                      Center(
                        child: Text(
                          'ElectionLeader Distributed Systems Engine • Spring Boot 3.5 WebFlux • Apache Curator • Redis Lettuce',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
