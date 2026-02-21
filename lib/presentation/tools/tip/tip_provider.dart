import 'package:flutter_riverpod/flutter_riverpod.dart';

class TipState {
  final double billAmount;
  final double tipPercent;
  final int splitCount;
  final double tipAmount;
  final double totalAmount;
  final double perPerson;

  const TipState({
    this.billAmount = 0,
    this.tipPercent = 18.0,
    this.splitCount = 1,
    this.tipAmount = 0,
    this.totalAmount = 0,
    this.perPerson = 0,
  });

  TipState copyWith({
    double? billAmount,
    double? tipPercent,
    int? splitCount,
    double? tipAmount,
    double? totalAmount,
    double? perPerson,
  }) =>
      TipState(
        billAmount: billAmount ?? this.billAmount,
        tipPercent: tipPercent ?? this.tipPercent,
        splitCount: splitCount ?? this.splitCount,
        tipAmount: tipAmount ?? this.tipAmount,
        totalAmount: totalAmount ?? this.totalAmount,
        perPerson: perPerson ?? this.perPerson,
      );
}

class TipNotifier extends StateNotifier<TipState> {
  TipNotifier() : super(const TipState());

  void setBillAmount(double v) {
    state = state.copyWith(billAmount: v);
    _calculate();
  }

  void setTipPercent(double v) {
    state = state.copyWith(tipPercent: v);
    _calculate();
  }

  void setSplitCount(int v) {
    if (v < 1) return;
    state = state.copyWith(splitCount: v);
    _calculate();
  }

  void incrementSplit() => setSplitCount(state.splitCount + 1);

  void decrementSplit() => setSplitCount(state.splitCount - 1);

  void _calculate() {
    final tip = state.billAmount * state.tipPercent / 100;
    final total = state.billAmount + tip;
    final pp = state.splitCount > 0 ? total / state.splitCount : total;
    state = state.copyWith(
      tipAmount: tip,
      totalAmount: total,
      perPerson: pp,
    );
  }
}

final tipProvider = StateNotifierProvider<TipNotifier, TipState>(
  (ref) => TipNotifier(),
);
