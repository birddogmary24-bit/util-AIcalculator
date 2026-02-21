import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplitBillState {
  final double totalAmount;
  final int peopleCount;
  final Map<int, double> adjustments;
  final double basePerPerson;
  final List<double> adjustedAmounts;

  const SplitBillState({
    this.totalAmount = 0,
    this.peopleCount = 2,
    this.adjustments = const {},
    this.basePerPerson = 0,
    this.adjustedAmounts = const [],
  });

  SplitBillState copyWith({
    double? totalAmount,
    int? peopleCount,
    Map<int, double>? adjustments,
    double? basePerPerson,
    List<double>? adjustedAmounts,
  }) =>
      SplitBillState(
        totalAmount: totalAmount ?? this.totalAmount,
        peopleCount: peopleCount ?? this.peopleCount,
        adjustments: adjustments ?? this.adjustments,
        basePerPerson: basePerPerson ?? this.basePerPerson,
        adjustedAmounts: adjustedAmounts ?? this.adjustedAmounts,
      );
}

class SplitBillNotifier extends StateNotifier<SplitBillState> {
  SplitBillNotifier() : super(const SplitBillState());

  void setTotalAmount(double v) {
    state = state.copyWith(totalAmount: v);
    _calculate();
  }

  void setPeopleCount(int v) {
    if (v < 1) return;
    // Remove adjustments for indices that no longer exist
    final cleaned = Map<int, double>.from(state.adjustments)
      ..removeWhere((key, _) => key >= v);
    state = state.copyWith(peopleCount: v, adjustments: cleaned);
    _calculate();
  }

  void incrementPeople() => setPeopleCount(state.peopleCount + 1);

  void decrementPeople() => setPeopleCount(state.peopleCount - 1);

  void setAdjustment(int personIndex, double amount) {
    final updated = Map<int, double>.from(state.adjustments);
    if (amount == 0) {
      updated.remove(personIndex);
    } else {
      updated[personIndex] = amount;
    }
    state = state.copyWith(adjustments: updated);
    _calculate();
  }

  void clearAdjustments() {
    state = state.copyWith(adjustments: {});
    _calculate();
  }

  void _calculate() {
    final count = state.peopleCount;
    if (count <= 0) return;

    final base = state.totalAmount / count;

    // Calculate the total of all adjustments
    double totalAdjustments = 0;
    for (final adj in state.adjustments.values) {
      totalAdjustments += adj;
    }

    // Build adjusted amounts: people with adjustments get base + adjustment,
    // the remainder is redistributed equally among unadjusted people.
    final adjustedPeople = state.adjustments.keys.toSet();
    final unadjustedCount = count - adjustedPeople.length;

    // Amount that adjusted people take extra (or less) from the pool
    final redistributed = unadjustedCount > 0
        ? -totalAdjustments / unadjustedCount
        : 0.0;

    final amounts = List<double>.generate(count, (i) {
      final adj = state.adjustments[i] ?? 0;
      final raw = adjustedPeople.contains(i) ? base + adj : base + redistributed;
      return raw < 0 ? 0 : raw;
    });

    state = state.copyWith(
      basePerPerson: base,
      adjustedAmounts: amounts,
    );
  }
}

final splitBillProvider =
    StateNotifierProvider<SplitBillNotifier, SplitBillState>(
  (ref) => SplitBillNotifier(),
);
