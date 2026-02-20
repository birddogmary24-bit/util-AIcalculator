import 'package:flutter_riverpod/flutter_riverpod.dart';

class PeriodState {
  final DateTime? lastPeriodDate;
  final int cycleLength;
  final int periodDuration;
  final DateTime? nextPeriodDate;
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final List<DateTime> nextThreePeriods;

  const PeriodState({
    this.lastPeriodDate,
    this.cycleLength = 28,
    this.periodDuration = 5,
    this.nextPeriodDate,
    this.ovulationDate,
    this.fertileStart,
    this.fertileEnd,
    this.nextThreePeriods = const [],
  });

  PeriodState copyWith({
    DateTime? lastPeriodDate,
    int? cycleLength,
    int? periodDuration,
    DateTime? nextPeriodDate,
    DateTime? ovulationDate,
    DateTime? fertileStart,
    DateTime? fertileEnd,
    List<DateTime>? nextThreePeriods,
  }) =>
      PeriodState(
        lastPeriodDate: lastPeriodDate ?? this.lastPeriodDate,
        cycleLength: cycleLength ?? this.cycleLength,
        periodDuration: periodDuration ?? this.periodDuration,
        nextPeriodDate: nextPeriodDate ?? this.nextPeriodDate,
        ovulationDate: ovulationDate ?? this.ovulationDate,
        fertileStart: fertileStart ?? this.fertileStart,
        fertileEnd: fertileEnd ?? this.fertileEnd,
        nextThreePeriods: nextThreePeriods ?? this.nextThreePeriods,
      );
}

class PeriodNotifier extends StateNotifier<PeriodState> {
  PeriodNotifier() : super(const PeriodState());

  void setLastPeriodDate(DateTime date) {
    state = state.copyWith(lastPeriodDate: date);
    _calculate();
  }

  void setCycleLength(int length) {
    state = state.copyWith(cycleLength: length);
    _calculate();
  }

  void setPeriodDuration(int duration) {
    state = state.copyWith(periodDuration: duration);
    _calculate();
  }

  void _calculate() {
    final lastDate = state.lastPeriodDate;
    if (lastDate == null) return;

    final cycle = state.cycleLength;

    // Next period
    final nextPeriod = lastDate.add(Duration(days: cycle));

    // Ovulation = lastPeriodDate + (cycleLength - 14) days
    final ovulation = lastDate.add(Duration(days: cycle - 14));

    // Fertile window: ovulation - 5 ~ ovulation + 1
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    // Next 3 periods
    final nextThree = <DateTime>[];
    for (int i = 1; i <= 3; i++) {
      nextThree.add(lastDate.add(Duration(days: cycle * i)));
    }

    state = state.copyWith(
      nextPeriodDate: nextPeriod,
      ovulationDate: ovulation,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      nextThreePeriods: nextThree,
    );
  }
}

final periodProvider =
    StateNotifierProvider<PeriodNotifier, PeriodState>((ref) => PeriodNotifier());
