import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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

    return ToolScaffold(
      title: 'D-day 계산기',
      children: [
        // ── Mode Selector ──────────────────────────────────────────────
        _buildModeSelector(state, notifier),
        const SizedBox(height: 20),

        // ── Today's Date ───────────────────────────────────────────────
        _buildTodayCard(),
        const SizedBox(height: 16),

        // ── Date Picker Card ───────────────────────────────────────────
        _buildDatePickerCard(state, notifier),
        const SizedBox(height: 24),

        // ── D-day Display ──────────────────────────────────────────────
        if (state.targetDate != null) ...[
          _buildDdayDisplay(state),
          const SizedBox(height: 16),

          // ── Detail Results ─────────────────────────────────────────
          _buildDetailResults(state),
        ],
      ],
    );
  }

  Widget _buildModeSelector(DdayState state, DdayNotifier notifier) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
            value: true,
            label: Text('D-day (남은 날)', style: TextStyle(fontSize: 15)),
          ),
          ButtonSegment(
            value: false,
            label: Text('지난 날 (경과일)', style: TextStyle(fontSize: 15)),
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

  Widget _buildTodayCard() {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final formatted = DateFormat('yyyy년 M월 d일').format(today);
    final weekday = _koreanWeekday(today.weekday);

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
                '오늘 날짜',
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

  Widget _buildDatePickerCard(DdayState state, DdayNotifier notifier) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = state.targetDate != null;
    final label = state.isDday ? '목표 날짜 선택' : '기준 날짜 선택';

    String dateText;
    if (hasDate) {
      final formatted = DateFormat('yyyy년 M월 d일').format(state.targetDate!);
      final weekday = _koreanWeekday(state.targetDate!.weekday);
      dateText = '$formatted ($weekday)';
    } else {
      dateText = '날짜를 선택해주세요';
    }

    return GestureDetector(
      onTap: () => _pickDate(notifier),
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

  Widget _buildDetailResults(DdayState state) {
    final cs = Theme.of(context).colorScheme;
    final absDays = (state.daysDiff ?? 0).abs();
    final formatter = NumberFormat('#,###');

    return Column(
      children: [
        ResultDisplayCard(
          label: '총 일수',
          value: formatter.format(absDays),
          unit: '일',
          accentColor: cs.primary,
        ),
        const SizedBox(height: 10),
        ResultDisplayCard(
          label: '주 단위',
          value: '${state.weeks}주 ${state.remainingDays}일',
          accentColor: cs.primary,
        ),
        const SizedBox(height: 10),
        ResultDisplayCard(
          label: '총 시간',
          value: formatter.format(state.totalHours),
          unit: '시간',
          accentColor: cs.primary,
        ),
      ],
    );
  }

  Future<void> _pickDate(DdayNotifier notifier) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('ko'),
    );
    if (picked != null) {
      notifier.setTargetDate(picked);
    }
  }

  String _koreanWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }
}
