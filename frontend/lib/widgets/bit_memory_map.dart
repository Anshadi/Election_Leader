import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../theme/app_theme.dart';
import 'clean_panel.dart';

class BitMemoryMap extends StatefulWidget {
  const BitMemoryMap({super.key});

  @override
  State<BitMemoryMap> createState() => _BitMemoryMapState();
}

class _BitMemoryMapState extends State<BitMemoryMap> {
  int selectedSegment = 1;
  final TextEditingController _customIdController = TextEditingController();

  @override
  void dispose() {
    _customIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardProvider>();
    final parsed = state.parsedId;

    final id = parsed != null ? parsed.id.toString() : '---';
    final deltaMs = parsed?.timestampDelta ?? 0;
    final nodeId = parsed?.nodeId ?? 0;
    final seq = parsed?.sequence ?? 0;
    final binary = parsed?.binary64Bit ?? ('0' * 64);

    String timeStr = '--:--:--';
    if (parsed != null && parsed.dateTime.isNotEmpty) {
      final parts = parsed.dateTime.split('T');
      if (parts.length > 1) {
        timeStr = parts[1].replaceAll('Z', '');
      } else {
        timeStr = parsed.dateTime;
      }
    }

    return CleanPanel(
      title: '64-BIT BIT-PACKED ALLOCATION MATRIX',
      badge: 'MEMORY LAYOUT',
      trailing: Text(
        'DEC: $id',
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decode Custom ID Search Field
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _customIdController,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter any 64-bit ID or Snowflake integer (e.g. 1025, 318729182371928371)...',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                    onSubmitted: (val) {
                      state.decodeCustomId(val);
                      _customIdController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  state.decodeCustomId(_customIdController.text);
                  _customIdController.clear();
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.code_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        'Decode',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick Sample Chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _SampleChip(
                label: 'Sample Node 1 ID',
                value: '1025',
                onTap: () => state.decodeCustomId('1025'),
              ),
              _SampleChip(
                label: 'Sample Node 2 ID',
                value: '2049',
                onTap: () => state.decodeCustomId('2049'),
              ),
              _SampleChip(
                label: 'Sample 64-bit Snowflake',
                value: '318729182371928371',
                onTap: () => state.decodeCustomId('318729182371928371'),
              ),
              if (state.currentId != null)
                _SampleChip(
                  label: 'Latest ID (#${state.currentId!.id})',
                  value: state.currentId!.id.toString(),
                  onTap: () => state.decodeCustomId(state.currentId!.id.toString()),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            'FIELD ALLOCATION MAP (CLICK SEGMENT TO INSPECT):',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _FieldTile(
                  label: 'SIGN',
                  bits: '63',
                  flex: 1,
                  color: AppColors.bitSign,
                  isSelected: selectedSegment == 0,
                  onTap: () => setState(() => selectedSegment = 0),
                ),
                const SizedBox(width: 3),
                _FieldTile(
                  label: 'TIMESTAMP',
                  bits: '35b',
                  flex: 4,
                  color: AppColors.bitTimestamp,
                  isSelected: selectedSegment == 1,
                  onTap: () => setState(() => selectedSegment = 1),
                ),
                const SizedBox(width: 3),
                _FieldTile(
                  label: 'NODE',
                  bits: '12b',
                  flex: 2,
                  color: AppColors.bitNode,
                  isSelected: selectedSegment == 2,
                  onTap: () => setState(() => selectedSegment = 2),
                ),
                const SizedBox(width: 3),
                _FieldTile(
                  label: 'SEQ',
                  bits: '16b',
                  flex: 3,
                  color: AppColors.bitSequence,
                  isSelected: selectedSegment == 3,
                  onTap: () => setState(() => selectedSegment = 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _buildInspectionBox(selectedSegment, deltaMs, timeStr, nodeId, seq, binary),
        ],
      ),
    );
  }

  Widget _buildInspectionBox(int index, int deltaMs, String timeStr, int nodeId, int seq, String binary) {
    String fieldName;
    String bitRange;
    String decVal;
    String formula;
    Color accentColor;

    switch (index) {
      case 0:
        fieldName = 'Sign Bit (Fixed 0)';
        bitRange = 'Bit 63 | Mask: 0x8000000000000000';
        decVal = '0 (Strictly Positive Signed Long)';
        formula = '(id >>> 63) & 1L == 0';
        accentColor = AppColors.bitSign;
        break;
      case 1:
        fieldName = 'Epoch Timestamp Delta (ms)';
        bitRange = 'Bits 62..28 (35 Bits) | Mask: 0x7FFFFFFFF0000000';
        decVal = '$deltaMs ms elapsed (UTC: $timeStr)';
        formula = '(id >>> 28) & 0x7FFFFFFFFL';
        accentColor = AppColors.bitTimestamp;
        break;
      case 2:
        fieldName = 'Cluster Node Identifier';
        bitRange = 'Bits 27..16 (12 Bits) | Mask: 0x000000000FFF0000';
        decVal = 'Node #$nodeId (0 to 4,095)';
        formula = '(id >>> 16) & 0x0FFFL';
        accentColor = AppColors.bitNode;
        break;
      case 3:
      default:
        fieldName = 'Millisecond Sequence Counter';
        bitRange = 'Bits 15..0 (16 Bits) | Mask: 0x000000000000FFFF';
        decVal = 'Seq #$seq (0 to 65,535)';
        formula = 'id & 0xFFFFL';
        accentColor = AppColors.bitSequence;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                fieldName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
              ),
              Text(
                bitRange,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Decoded Value: $decVal',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Shift/Mask Expression: $formula',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            'Binary (64-Bit): $binary',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9.5,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SampleChip({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String bits;
  final int flex;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FieldTile({
    required this.label,
    required this.bits,
    required this.flex,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                bits,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
