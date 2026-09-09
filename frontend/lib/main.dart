import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/dashboard_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/background_glow_painter.dart';
import 'widgets/header_bar.dart';
import 'widgets/live_generator_card.dart';
import 'widgets/cluster_topology_card.dart';
import 'widgets/bit_inspector_ribbon.dart';
import 'widgets/latency_sla_card.dart';
import 'widgets/stream_feed_card.dart';

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
      title: 'ElectionLeader Control Center',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Glowing Grid Canvas
          Positioned.fill(
            child: CustomPaint(
              painter: BackgroundGlowPainter(),
            ),
          ),

          // Main Scrollable Dashboard Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 950;
                final contentPadding = EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 20,
                );

                return SingleChildScrollView(
                  padding: contentPadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Header
                          const HeaderBar(),
                          const SizedBox(height: 24),

                          // Row 1: Live Generator & Cluster Topology
                          if (isWide)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: LiveGeneratorCard()),
                                SizedBox(width: 20),
                                Expanded(flex: 5, child: ClusterTopologyCard()),
                              ],
                            )
                          else ...[
                            const LiveGeneratorCard(),
                            const SizedBox(height: 16),
                            const ClusterTopologyCard(),
                          ],
                          const SizedBox(height: 20),

                          // Row 2: 64-Bit Interactive Ribbon
                          const BitInspectorRibbon(),
                          const SizedBox(height: 20),

                          // Row 3: Latency SLA & Stream Feed
                          if (isWide)
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 5, child: LatencySlaCard()),
                                SizedBox(width: 20),
                                Expanded(flex: 5, child: StreamFeedCard()),
                              ],
                            )
                          else ...[
                            const LatencySlaCard(),
                            const SizedBox(height: 16),
                            const StreamFeedCard(),
                          ],
                          const SizedBox(height: 30),

                          // Footer
                          Center(
                            child: Text(
                              'ElectionLeader Distributed Engine • Spring Boot 3.5 WebFlux • Apache Curator • Redis Lettuce • Flutter UI',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
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
        ],
      ),
    );
  }
}
