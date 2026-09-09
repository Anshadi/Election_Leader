import 'package:flutter/material.dart';
//
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'glass_card.dart';

class BitInspectorRibbon extends StatefulWidget {
  const BitInspectorRibbon({super.key});

  @override
  State<BitInspectorRibbon> createState() => _BitInspectorRibbonState();
}

class _BitInspectorRibbonState extends State<BitInspectorRibbon> {
  final TextEditingController _decodeController = TextEditingController();
  int selectedSegmentIndex = 1; // 0: Sign, 1: Timestamp, 2: Node, 3: Sequence

  @override
  void dispose() {
    _decodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final parsed = state.parsedId;

    final idStr = parsed?.id.toString() ?? '---';
    final timeStr = parsed?.dateTime ?? '--';
    final deltaMs = parsed?.timestampDelta ?? 0;
    final nodeId = parsed?.nodeId ?? 0;
    final seq = parsed?.sequence ?? 0;
    final binary = parsed?.binaryRepresentation ?? '0 00000000000000000000000000000000000 000000000000 0000000000000000';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Decoder input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Interactive 64-Bit Inspector',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'K-Ordered 63-bit Positive Long',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom ID input field
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: TextField(
                      controller: _decodeController,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Paste custom 64-bit ID to reverse-engineer (e.g. $idStr)',
                        hintStyle: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (val) => state.decodeCustomId(val),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => state.decodeCustomId(_decodeController.text),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Decode'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 64-Bit Visual Ribbon Strip
          Text(
            'Bit Allocation Breakdown [Tap to Inspect Field]:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    // Sign bit (1 bit)
                    _BitSegmentButton(
                      label: 'Sign\n1b',
                      range: '63',
                      color: AppColors.bitSign,
                      flex: 1,
                      isSelected: selectedSegmentIndex == 0,
                      onTap: () => setState(() => selectedSegmentIndex = 0),
                    ),
                    const SizedBox(width: 4),

                    // Timestamp delta (35 bits)
                    _BitSegmentButton(
                      label: 'Timestamp Delta\n35-Bit ($deltaMs ms)',
                      range: '62..28',
                      color: AppColors.bitTimestamp,
                      flex: 5,
                      isSelected: selectedSegmentIndex == 1,
                      onTap: () => setState(() => selectedSegmentIndex = 1),
                    ),
                    const SizedBox(width: 4),

                    // Node ID (12 bits)
                    _BitSegmentButton(
                      label: 'Node ID\n12-Bit (#$nodeId)',
                      range: '27..16',
                      color: AppColors.bitNode,
                      flex: 2,
                      isSelected: selectedSegmentIndex == 2,
                      onTap: () => setState(() => selectedSegmentIndex = 2),
                    ),
                    const SizedBox(width: 4),

                    // Sequence (16 bits)
                    _BitSegmentButton(
                      label: 'Sequence\n16-Bit (#$seq)',
                      range: '15..0',
                      color: AppColors.bitSequence,
                      flex: 3,
                      isSelected: selectedSegmentIndex == 3,
                      onTap: () => setState(() => selectedSegmentIndex = 3),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Dynamic Inspector Detail Card based on selectedSegmentIndex
          _buildSegmentDetailCard(selectedSegmentIndex, deltaMs, timeStr, nodeId, seq, binary),
        ],
      ),
    );
  }

  Widget _buildSegmentDetailCard(int index, int deltaMs, String timeStr, int nodeId, int seq, String binary) {
    String title;
    String bitsRange;
    String decValue;
    String desc;
    Color accentColor;

    switch (index) {
      case 0:
        title = 'Unused Sign Bit';
        bitsRange = 'Bit 63 (1 Bit)';
        decValue = '0';
        desc = 'Guarantees the 64-bit integer remains strictly positive in Java signed long representation.';
        accentColor = AppColors.bitSign;
        break;
      case 1:
        title = 'Epoch Timestamp Delta';
        bitsRange = 'Bits 62..28 (35 Bits)';
        decValue = '$deltaMs ms elapsed (UTC: $timeStr)';
        desc = 'Milliseconds since custom epoch. Supports over ~1.1 years of continuous millisecond precision.';
        accentColor = AppColors.bitTimestamp;
        break;
      case 2:
        title = 'Cluster Node Identifier';
        bitsRange = 'Bits 27..16 (12 Bits)';
        decValue = 'Node #$nodeId (Capacity: 0 to 4,095)';
        desc = 'Dynamically claimed via ZooKeeper sequential ephemeral nodes to eliminate multi-node collisions.';
        accentColor = AppColors.bitNode;
        break;
      case 3:
      default:
        title = 'Millisecond Sequence Counter';
        bitsRange = 'Bits 15..0 (16 Bits)';
        decValue = 'Seq #$seq (Capacity: 0 to 65,535)';
        desc = 'Allows generating up to 65,536 unique IDs per millisecond per instance (~65.5 million IDs/sec).';
        accentColor = AppColors.bitSequence;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: accentColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bitsRange,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Decoded Value: $decValue',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            'Binary Track: $binary',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _BitSegmentButton extends StatelessWidget {
  final String label;
  final String range;
  final Color color;
  final int flex;
  final bool isSelected;
  final VoidCallback onTap;

  const _BitSegmentButton({
    required this.label,
    required this.range,
    required this.color,
    required this.flex,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(isSelected ? 0.35 : 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.3),
              width: isSelected ? 1.8 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                range,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
