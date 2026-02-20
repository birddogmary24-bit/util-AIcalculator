import 'package:flutter_riverpod/flutter_riverpod.dart';

class DdayState {
  final DateTime? targetDate;
  final bool isDday; // true = counting down (D-day), false = counting up (경과일)
  final int? daysDiff;

  const DdayState({
    this.targetDate,
    this.isDday = true,
    this.daysDiff,
  });

  DdayState copyWith({
    DateTime? targetDate,
    bool? isDday,
    int? daysDiff,
  }) =>
      DdayState(
        targetDate: targetDate ?? this.targetDate,
        isDday: isDday ?? this.isDday,
        daysDiff: daysDiff ?? this.daysDiff,
      );

  /// Weeks component of daysDiff
  int get weeks => (daysDiff ?? 0).abs() ~/ 7;

  /// Remaining days after full weeks
  int get remainingDays => (daysDiff ?? 0).abs() % 7;

  /// Total hours
  int get totalHours => (daysDiff ?? 0).abs() * 24;

  /// Display text (D-37, D+150, D-Day)
  String get displayText {
    final d = daysDiff;
    if (d == null) return '';
    if (d == 0) return 'D-Day';
    if (isDday) {
      return d > 0 ? 'D-$d' : 'D+${d.abs()}';
    } else {
      return d > 0 ? 'D+$d' : 'D-${d.abs()}';
    }
  }
}

class DdayNotifier extends StateNotifier<DdayState> {
  DdayNotifier() : super(const DdayState());

  void setTargetDate(DateTime date) {
    state = state.copyWith(targetDate: date);
    _calculate();
  }

  void setMode(bool isDday) {
    state = state.copyWith(isDday: isDday);
    _calculate();
  }

  void _calculate() {
    final target = state.targetDate;
    if (target == null) {
      state = state.copyWith(daysDiff: null);
      return;
    }

    final today = _dateOnly(DateTime.now());
    final targetOnly = _dateOnly(target);

    int diff;
    if (state.isDday) {
      // D-day mode: positive = future (D-37), negative = past (D+150)
      diff = targetOnly.difference(today).inDays;
    } else {
      // 경과일 mode: positive = past days elapsed
      diff = today.difference(targetOnly).inDays;
    }

    state = state.copyWith(daysDiff: diff);
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

final ddayProvider =
    StateNotifierProvider<DdayNotifier, DdayState>((ref) => DdayNotifier());
