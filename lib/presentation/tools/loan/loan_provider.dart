import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum RepaymentType { equalPrincipalInterest, equalPrincipal }

class LoanScheduleEntry {
  final int month;
  final double payment;
  final double principalPortion;
  final double interestPortion;
  final double remainingBalance;

  const LoanScheduleEntry({
    required this.month,
    required this.payment,
    required this.principalPortion,
    required this.interestPortion,
    required this.remainingBalance,
  });
}

class LoanState {
  final double principal;
  final double annualRate;
  final int periodMonths;
  final RepaymentType repaymentType;
  final double monthlyPayment;
  final double totalInterest;
  final double totalRepayment;
  final double lastMonthPayment;
  final List<LoanScheduleEntry> schedule;

  const LoanState({
    this.principal = 0,
    this.annualRate = 0,
    this.periodMonths = 36,
    this.repaymentType = RepaymentType.equalPrincipalInterest,
    this.monthlyPayment = 0,
    this.totalInterest = 0,
    this.totalRepayment = 0,
    this.lastMonthPayment = 0,
    this.schedule = const [],
  });

  LoanState copyWith({
    double? principal,
    double? annualRate,
    int? periodMonths,
    RepaymentType? repaymentType,
    double? monthlyPayment,
    double? totalInterest,
    double? totalRepayment,
    double? lastMonthPayment,
    List<LoanScheduleEntry>? schedule,
  }) {
    return LoanState(
      principal: principal ?? this.principal,
      annualRate: annualRate ?? this.annualRate,
      periodMonths: periodMonths ?? this.periodMonths,
      repaymentType: repaymentType ?? this.repaymentType,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalInterest: totalInterest ?? this.totalInterest,
      totalRepayment: totalRepayment ?? this.totalRepayment,
      lastMonthPayment: lastMonthPayment ?? this.lastMonthPayment,
      schedule: schedule ?? this.schedule,
    );
  }
}

class LoanNotifier extends StateNotifier<LoanState> {
  LoanNotifier() : super(const LoanState());

  void setPrincipal(double v) {
    state = state.copyWith(principal: v);
    _calculate();
  }

  void setAnnualRate(double v) {
    state = state.copyWith(annualRate: v);
    _calculate();
  }

  void setPeriodMonths(int v) {
    state = state.copyWith(periodMonths: v);
    _calculate();
  }

  void setRepaymentType(RepaymentType v) {
    state = state.copyWith(repaymentType: v);
    _calculate();
  }

  void _calculate() {
    final p = state.principal;
    final rate = state.annualRate;
    final n = state.periodMonths;

    if (p <= 0 || rate <= 0 || n <= 0) {
      state = state.copyWith(
        monthlyPayment: 0,
        totalInterest: 0,
        totalRepayment: 0,
        lastMonthPayment: 0,
        schedule: [],
      );
      return;
    }

    final r = rate / 12.0 / 100.0; // monthly rate

    if (state.repaymentType == RepaymentType.equalPrincipalInterest) {
      _calcEqualPrincipalInterest(p, r, n);
    } else {
      _calcEqualPrincipal(p, r, n);
    }
  }

  void _calcEqualPrincipalInterest(double p, double r, int n) {
    // M = P * r * (1+r)^n / ((1+r)^n - 1)
    final compoundFactor = pow(1 + r, n).toDouble();
    final monthlyPayment = p * r * compoundFactor / (compoundFactor - 1);
    final totalRepayment = monthlyPayment * n;
    final totalInterest = totalRepayment - p;

    // Build schedule (first 12 months max for display)
    final schedule = <LoanScheduleEntry>[];
    double remaining = p;
    final limit = n < 12 ? n : 12;
    for (int i = 1; i <= limit; i++) {
      final interest = remaining * r;
      final principal = monthlyPayment - interest;
      remaining -= principal;
      if (remaining < 0) remaining = 0;
      schedule.add(LoanScheduleEntry(
        month: i,
        payment: monthlyPayment,
        principalPortion: principal,
        interestPortion: interest,
        remainingBalance: remaining,
      ));
    }

    state = state.copyWith(
      monthlyPayment: monthlyPayment,
      totalInterest: totalInterest,
      totalRepayment: totalRepayment,
      lastMonthPayment: monthlyPayment,
      schedule: schedule,
    );
  }

  void _calcEqualPrincipal(double p, double r, int n) {
    final monthlyPrincipal = p / n;
    final firstInterest = p * r;
    final firstPayment = monthlyPrincipal + firstInterest;

    // Total interest = P * r * (n + 1) / 2
    final totalInterest = p * r * (n + 1) / 2;
    final totalRepayment = p + totalInterest;

    // Last month payment
    final lastInterest = monthlyPrincipal * r; // remaining = monthlyPrincipal
    final lastPayment = monthlyPrincipal + lastInterest;

    // Build schedule (first 12 months max for display)
    final schedule = <LoanScheduleEntry>[];
    double remaining = p;
    final limit = n < 12 ? n : 12;
    for (int i = 1; i <= limit; i++) {
      final interest = remaining * r;
      final payment = monthlyPrincipal + interest;
      remaining -= monthlyPrincipal;
      if (remaining < 0) remaining = 0;
      schedule.add(LoanScheduleEntry(
        month: i,
        payment: payment,
        principalPortion: monthlyPrincipal,
        interestPortion: interest,
        remainingBalance: remaining,
      ));
    }

    state = state.copyWith(
      monthlyPayment: firstPayment,
      totalInterest: totalInterest,
      totalRepayment: totalRepayment,
      lastMonthPayment: lastPayment,
      schedule: schedule,
    );
  }
}

final loanProvider =
    StateNotifierProvider<LoanNotifier, LoanState>((ref) => LoanNotifier());
