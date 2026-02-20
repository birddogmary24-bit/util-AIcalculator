import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VatMode { inclusive, exclusive }

class VatState {
  final double amount;
  final VatMode mode;
  final double supplyAmount;
  final double vatAmount;
  final double totalAmount;

  const VatState({
    this.amount = 0,
    this.mode = VatMode.exclusive,
    this.supplyAmount = 0,
    this.vatAmount = 0,
    this.totalAmount = 0,
  });

  VatState copyWith({
    double? amount,
    VatMode? mode,
    double? supplyAmount,
    double? vatAmount,
    double? totalAmount,
  }) =>
      VatState(
        amount: amount ?? this.amount,
        mode: mode ?? this.mode,
        supplyAmount: supplyAmount ?? this.supplyAmount,
        vatAmount: vatAmount ?? this.vatAmount,
        totalAmount: totalAmount ?? this.totalAmount,
      );
}

class VatNotifier extends StateNotifier<VatState> {
  VatNotifier() : super(const VatState());

  void setAmount(double v) {
    state = state.copyWith(amount: v);
    _calculate();
  }

  void setMode(VatMode v) {
    state = state.copyWith(mode: v);
    _calculate();
  }

  void _calculate() {
    final a = state.amount;
    if (a <= 0) {
      state = state.copyWith(supplyAmount: 0, vatAmount: 0, totalAmount: 0);
      return;
    }

    double supply;
    double vat;
    double total;

    if (state.mode == VatMode.inclusive) {
      // 입력 금액에 부가세가 포함된 경우
      supply = a / 1.1;
      vat = a - supply;
      total = a;
    } else {
      // 입력 금액에 부가세가 미포함된 경우
      supply = a;
      vat = a * 0.1;
      total = a + vat;
    }

    state = state.copyWith(
      supplyAmount: supply,
      vatAmount: vat,
      totalAmount: total,
    );
  }
}

final vatProvider = StateNotifierProvider<VatNotifier, VatState>(
  (ref) => VatNotifier(),
);
