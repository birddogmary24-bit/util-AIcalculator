import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionType { sale, lease }

class BrokerageFeeState {
  final TransactionType type;
  final double saleAmount;
  final double deposit;
  final double monthlyRent;
  final double rate;
  final double fee;
  final double? cap;
  final bool hasCap;

  const BrokerageFeeState({
    this.type = TransactionType.sale,
    this.saleAmount = 0,
    this.deposit = 0,
    this.monthlyRent = 0,
    this.rate = 0,
    this.fee = 0,
    this.cap,
    this.hasCap = false,
  });

  BrokerageFeeState copyWith({
    TransactionType? type,
    double? saleAmount,
    double? deposit,
    double? monthlyRent,
    double? rate,
    double? fee,
    double? cap,
    bool? hasCap,
  }) {
    return BrokerageFeeState(
      type: type ?? this.type,
      saleAmount: saleAmount ?? this.saleAmount,
      deposit: deposit ?? this.deposit,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      rate: rate ?? this.rate,
      fee: fee ?? this.fee,
      cap: cap ?? this.cap,
      hasCap: hasCap ?? this.hasCap,
    );
  }
}

class BrokerageFeeNotifier extends StateNotifier<BrokerageFeeState> {
  BrokerageFeeNotifier() : super(const BrokerageFeeState());

  void setType(TransactionType v) {
    state = state.copyWith(type: v);
    _calculate();
  }

  void setSaleAmount(double v) {
    state = state.copyWith(saleAmount: v);
    _calculate();
  }

  void setDeposit(double v) {
    state = state.copyWith(deposit: v);
    _calculate();
  }

  void setMonthlyRent(double v) {
    state = state.copyWith(monthlyRent: v);
    _calculate();
  }

  void _calculate() {
    double amount;

    if (state.type == TransactionType.sale) {
      amount = state.saleAmount;
    } else {
      // 임대 환산: 보증금 + (월세 x 100)
      amount = state.deposit + (state.monthlyRent * 100);
    }

    if (amount <= 0) {
      state = state.copyWith(rate: 0, fee: 0, cap: 0, hasCap: false);
      return;
    }

    double rate;
    double? cap;

    if (state.type == TransactionType.sale) {
      // 매매/교환 요율표 (2024 기준)
      if (amount < 50000000) {
        rate = 0.6;
        cap = 250000;
      } else if (amount < 200000000) {
        rate = 0.5;
        cap = 800000;
      } else if (amount < 900000000) {
        rate = 0.4;
        cap = null;
      } else if (amount < 1200000000) {
        rate = 0.5;
        cap = null;
      } else if (amount < 1500000000) {
        rate = 0.6;
        cap = null;
      } else {
        rate = 0.7;
        cap = null;
      }
    } else {
      // 임대차 요율표 (2024 기준)
      if (amount < 50000000) {
        rate = 0.5;
        cap = 200000;
      } else if (amount < 100000000) {
        rate = 0.4;
        cap = 300000;
      } else if (amount < 600000000) {
        rate = 0.3;
        cap = null;
      } else if (amount < 1200000000) {
        rate = 0.4;
        cap = null;
      } else if (amount < 1500000000) {
        rate = 0.5;
        cap = null;
      } else {
        rate = 0.6;
        cap = null;
      }
    }

    double fee = amount * rate / 100.0;

    final bool hasCap = cap != null && fee > cap;
    if (hasCap) {
      fee = cap;
    }

    state = state.copyWith(
      rate: rate,
      fee: fee,
      cap: cap ?? 0,
      hasCap: hasCap,
    );
  }
}

final brokerageFeeProvider =
    StateNotifierProvider<BrokerageFeeNotifier, BrokerageFeeState>(
        (ref) => BrokerageFeeNotifier());
