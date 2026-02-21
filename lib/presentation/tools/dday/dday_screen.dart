import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/result_display_card.dart';
import 'dday_provider.dart';

class DdayScreen extends ConsumerStatefulWidget {
  const DdayScreen({super.key});

  @override
  ConsumerState<DdayScreen> createState() => _DdayScreenState();
}

class _DdayScreenState extends ConsumerState<DdayScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ddayProvider);
    final notifier = ref.read(ddayProvider.notifier);
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    return ToolScaffold(
      title: isKr ? 'D-day 계산기' : 'D-day Calculator',
      children: [
        // ── Mode Selector ──────────────────────────────────────────────
        _buildModeSelector(state, notifier, isKr),
        const SizedBox(height: 20),

        // ── Today's Date ───────────────────────────────────────────────
        _buildTodayCard(isKr),
        const SizedBox(height: 16),

        // ── Date Picker Card ───────────────────────────────────────────
        _buildDatePickerCard(state, notifier, isKr),
        const SizedBox(height: 24),

        // ── D-day Display ──────────────────────────────────────────────
        if (state.targetDate != null) ...[
          _buildDdayDisplay(state),
          const SizedBox(height: 16),

          // ── Detail Results ─────────────────────────────────────────
          _buildDetailResults(state, isKr),
        ],
      ],
    );
  }

  Widget _buildModeSelector(DdayState state, DdayNotifier notifier, bool isKr) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(
            value: true,
            label: Text(
              isKr ? 'D-day (남은 날)' : 'D-day (Remaining)',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          ButtonSegment(
            value: false,
            label: Text(
              isKr ? '지난 날 (경과일)' : 'Days Passed (Elapsed)',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
        selected: {state.isDday},
        onSelectionChanged: (selected) {
          notifier.setMode(selected.first);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          selectedBackgroundColor: cs.primary,
          selectedForegroundColor: cs.onPrimary,
          foregroundColor: cs.onSurface,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildTodayCard(bool isKr) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final formatted = isKr
        ? DateFormat('yyyy년 M월 d일').format(today)
        : DateFormat('MMM d, yyyy').format(today);
    final weekday = isKr
        ? _koreanWeekday(today.weekday)
        : _englishWeekday(today.weekday);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.today, color: cs.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isKr ? '오늘 날짜' : 'Today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurfaceVariant,
                ),
              ),
              Text(
                '$formatted ($weekday)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerCard(DdayState state, DdayNotifier notifier, bool isKr) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = state.targetDate != null;
    final label = state.isDday
        ? (isKr ? '목표 날짜 선택' : 'Select Target Date')
        : (isKr ? '기준 날짜 선택' : 'Select Start Date');

    String dateText;
    if (hasDate) {
      if (isKr) {
        final formatted = DateFormat('yyyy년 M월 d일').format(state.targetDate!);
        final weekday = _koreanWeekday(state.targetDate!.weekday);
        dateText = '$formatted ($weekday)';
      } else {
        final formatted = DateFormat('MMM d, yyyy').format(state.targetDate!);
        final weekday = _englishWeekday(state.targetDate!.weekday);
        dateText = '$formatted ($weekday)';
      }
    } else {
      dateText = isKr ? '날짜를 선택해주세요' : 'Select a date';
    }

    return GestureDetector(
      onTap: () => _pickDate(notifier, isKr),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_month,
              color: hasDate ? cs.primary : cs.onSurfaceVariant,
              size: 36,
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              dateText,
              style: TextStyle(
                fontSize: hasDate ? 20 : 17,
                fontWeight: FontWeight.w600,
                color: hasDate ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDdayDisplay(DdayState state) {
    final cs = Theme.of(context).colorScheme;
    final displayText = state.displayText;

    Color displayColor;
    if (state.daysDiff == 0) {
      displayColor = cs.error;
    } else if (state.isDday && (state.daysDiff ?? 0) > 0) {
      displayColor = cs.primary;
    } else {
      displayColor = cs.onSurface;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          displayText,
          style: GoogleFonts.robotoMono(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: displayColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailResults(DdayState state, bool isKr) {
    final cs = Theme.of(context).colorScheme;
    final absDays = (state.daysDiff ?? 0).abs();
    final formatter = NumberFormat('#,###');

    return Column(
      children: [
        ResultDisplayCard(
          label: isKr ? '총 일수' : 'Total Days',
          value: formatter.format(absDays),
          unit: isKr ? '일' : 'days',
          accentColor: cs.primary,
        ),
        const SizedBox(height: 10),
        ResultDisplayCard(
          label: isKr ? '주 단위' : 'Weeks',
          value: isKr
              ? '${state.weeks}주 ${state.remainingDays}일'
              : '${state.weeks}w ${state.remainingDays}d',
          accentColor: cs.primary,
        ),
        const SizedBox(height: 10),
        ResultDisplayCard(
          label: isKr ? '총 시간' : 'Total Hours',
          value: formatter.format(state.totalHours),
          unit: isKr ? '시간' : 'hrs',
          accentColor: cs.primary,
        ),
      ],
    );
  }

  Future<void> _pickDate(DdayNotifier notifier, bool isKr) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: isKr ? const Locale('ko') : const Locale('en'),
    );
    if (picked != null) {
      notifier.setTargetDate(picked);
    }
  }

  String _koreanWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  String _englishWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
