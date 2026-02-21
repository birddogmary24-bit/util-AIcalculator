import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import '../../common/widgets/tool_scaffold.dart';
import '../../common/widgets/result_display_card.dart';
import 'period_provider.dart';

class PeriodScreen extends ConsumerStatefulWidget {
  const PeriodScreen({super.key});

  @override
  ConsumerState<PeriodScreen> createState() => _PeriodScreenState();
}

class _PeriodScreenState extends ConsumerState<PeriodScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(periodProvider);
    final notifier = ref.read(periodProvider.notifier);
    final region = ref.watch(regionProvider);

    return ToolScaffold(
      title: region == RegionMode.kr ? '생리 계산기' : 'Period Calculator',
      children: [
        // ── Last Period Date Picker ─────────────────────────────────────
        _buildDatePickerCard(state, notifier, region),
        const SizedBox(height: 20),

        // ── Cycle Length Slider ─────────────────────────────────────────
        _buildSlider(
          label: region == RegionMode.kr ? '평균 주기' : 'Avg. Cycle',
          value: state.cycleLength,
          min: 21,
          max: 40,
          unit: region == RegionMode.kr ? '일' : 'days',
          onChanged: (v) => notifier.setCycleLength(v.round()),
        ),
        const SizedBox(height: 16),

        // ── Period Duration Slider ──────────────────────────────────────
        _buildSlider(
          label: region == RegionMode.kr ? '생리 기간' : 'Period Duration',
          value: state.periodDuration,
          min: 3,
          max: 7,
          unit: region == RegionMode.kr ? '일' : 'days',
          onChanged: (v) => notifier.setPeriodDuration(v.round()),
        ),
        const SizedBox(height: 24),

        // ── Results ────────────────────────────────────────────────────
        if (state.lastPeriodDate != null) ...[
          _buildSectionTitle(
              region == RegionMode.kr ? '예측 결과' : 'Prediction Results'),
          const SizedBox(height: 12),
          _buildResultCards(state, region),
          const SizedBox(height: 24),

          // ── Timeline ──────────────────────────────────────────────
          _buildSectionTitle(
              region == RegionMode.kr ? '다음 주기 타임라인' : 'Next Cycle Timeline'),
          const SizedBox(height: 12),
          _buildTimeline(state, region),
          const SizedBox(height: 24),

          // ── Next 3 Periods ────────────────────────────────────────
          _buildSectionTitle(
              region == RegionMode.kr ? '향후 3회 예정일' : 'Next 3 Periods'),
          const SizedBox(height: 12),
          _buildNextThreePeriods(state, region),
        ],
      ],
    );
  }

  Widget _buildDatePickerCard(
      PeriodState state, PeriodNotifier notifier, RegionMode region) {
    final cs = Theme.of(context).colorScheme;
    final hasDate = state.lastPeriodDate != null;
    String dateText;
    if (hasDate) {
      if (region == RegionMode.kr) {
        final formatted =
            DateFormat('yyyy년 M월 d일').format(state.lastPeriodDate!);
        final weekday = _koreanWeekday(state.lastPeriodDate!.weekday);
        dateText = '$formatted ($weekday)';
      } else {
        dateText =
            DateFormat('MMM d, yyyy (E)').format(state.lastPeriodDate!);
      }
    } else {
      dateText = region == RegionMode.kr ? '날짜를 선택해주세요' : 'Select a date';
    }

    return GestureDetector(
      onTap: () => _pickDate(notifier, region),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: hasDate ? const Color(0xFFE53E3E) : cs.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    region == RegionMode.kr
                        ? '마지막 생리 시작일'
                        : 'Last Period Start Date',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateText,
                    style: TextStyle(
                      fontSize: hasDate ? 19 : 16,
                      fontWeight: FontWeight.w600,
                      color: hasDate ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required int min,
    required int max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$value $unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withAlpha(30),
              trackHeight: 6,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: onChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$min $unit',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              Text(
                '$max $unit',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final cs = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }

  Widget _buildResultCards(PeriodState state, RegionMode region) {
    final dateFormat = region == RegionMode.kr
        ? DateFormat('M월 d일')
        : DateFormat('MMM d');

    return Column(
      children: [
        // Next period (red)
        ResultDisplayCard(
          label: region == RegionMode.kr ? '다음 생리 예정일' : 'Next Expected Date',
          value: state.nextPeriodDate != null
              ? _formatDateWithWeekday(state.nextPeriodDate!, region)
              : '-',
          accentColor: const Color(0xFFE53E3E),
        ),
        const SizedBox(height: 10),

        // Ovulation (blue)
        ResultDisplayCard(
          label: region == RegionMode.kr ? '배란 예정일' : 'Ovulation Date',
          value: state.ovulationDate != null
              ? _formatDateWithWeekday(state.ovulationDate!, region)
              : '-',
          accentColor: const Color(0xFF3182CE),
        ),
        const SizedBox(height: 10),

        // Fertile window (pink)
        ResultDisplayCard(
          label: region == RegionMode.kr ? '가임기' : 'Fertile Window',
          value: (state.fertileStart != null && state.fertileEnd != null)
              ? '${dateFormat.format(state.fertileStart!)} ~ ${dateFormat.format(state.fertileEnd!)}'
              : '-',
          accentColor: const Color(0xFFED64A6),
        ),
      ],
    );
  }

  Widget _buildTimeline(PeriodState state, RegionMode region) {
    final cs = Theme.of(context).colorScheme;

    if (state.lastPeriodDate == null) return const SizedBox.shrink();

    final items = <_TimelineItem>[
      _TimelineItem(
        label: region == RegionMode.kr ? '생리 시작' : 'Period Start',
        date: state.lastPeriodDate!,
        color: const Color(0xFFE53E3E),
        icon: Icons.circle,
      ),
      if (state.fertileStart != null)
        _TimelineItem(
          label: region == RegionMode.kr ? '가임기 시작' : 'Fertile Start',
          date: state.fertileStart!,
          color: const Color(0xFFED64A6),
          icon: Icons.favorite,
        ),
      if (state.ovulationDate != null)
        _TimelineItem(
          label: region == RegionMode.kr ? '배란일' : 'Ovulation',
          date: state.ovulationDate!,
          color: const Color(0xFF3182CE),
          icon: Icons.star,
        ),
      if (state.fertileEnd != null)
        _TimelineItem(
          label: region == RegionMode.kr ? '가임기 종료' : 'Fertile End',
          date: state.fertileEnd!,
          color: const Color(0xFFED64A6),
          icon: Icons.favorite_border,
        ),
      if (state.nextPeriodDate != null)
        _TimelineItem(
          label: region == RegionMode.kr ? '다음 생리' : 'Next Period',
          date: state.nextPeriodDate!,
          color: const Color(0xFFE53E3E),
          icon: Icons.circle,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline dot and line
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Icon(item.icon, color: item.color, size: 18),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: cs.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: item.color,
                          ),
                        ),
                        Text(
                          DateFormat('M/d').format(item.date),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNextThreePeriods(PeriodState state, RegionMode region) {
    if (state.nextThreePeriods.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(state.nextThreePeriods.length, (index) {
        final date = state.nextThreePeriods[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ResultDisplayCard(
            label: region == RegionMode.kr
                ? '${index + 1}회차'
                : 'Cycle ${index + 1}',
            value: _formatDateWithWeekday(date, region),
            accentColor: const Color(0xFFE53E3E),
          ),
        );
      }),
    );
  }

  Future<void> _pickDate(PeriodNotifier notifier, RegionMode region) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      locale: region == RegionMode.kr ? const Locale('ko') : const Locale('en'),
    );
    if (picked != null) {
      notifier.setLastPeriodDate(picked);
    }
  }

  String _formatDateWithWeekday(DateTime date, RegionMode region) {
    if (region == RegionMode.kr) {
      final formatted = DateFormat('yyyy년 M월 d일').format(date);
      final weekday = _koreanWeekday(date.weekday);
      return '$formatted ($weekday)';
    } else {
      return DateFormat('MMM d, yyyy (E)').format(date);
    }
  }

  String _koreanWeekday(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }
}

// ── Helper model ───────────────────────────────────────────────────────────

class _TimelineItem {
  final String label;
  final DateTime date;
  final Color color;
  final IconData icon;

  const _TimelineItem({
    required this.label,
    required this.date,
    required this.color,
    required this.icon,
  });
}
