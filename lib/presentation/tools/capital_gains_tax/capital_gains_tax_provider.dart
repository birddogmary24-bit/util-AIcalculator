import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Enums ────────────────────────────────────────────────────────────────────

enum HoldingPeriod { underOneYear, oneToTwo, overTwo }

enum HouseCount { one, two, threeOrMore }

// ── Tax bracket entry ────────────────────────────────────────────────────────

class _TaxBracket {
  final double upperLimit; // inclusive upper bound (won)
  final double rate; // percent (e.g. 6 for 6%)
  final double progressiveDeduction; // 누진공제 (won)
  const _TaxBracket(this.upperLimit, this.rate, this.progressiveDeduction);
}

const List<_TaxBracket> _brackets = [
  _TaxBracket(14000000, 6, 0),
  _TaxBracket(50000000, 15, 1260000),
  _TaxBracket(88000000, 24, 5760000),
  _TaxBracket(150000000, 35, 15440000),
  _TaxBracket(300000000, 38, 19940000),
  _TaxBracket(500000000, 40, 25940000),
  _TaxBracket(1000000000, 42, 35940000),
  _TaxBracket(double.infinity, 45, 65940000),
];

// ── State ────────────────────────────────────────────────────────────────────

class CapitalGainsTaxState {
  // inputs
  final double sellingPrice;
  final double purchasePrice;
  final double expenses;
  final HoldingPeriod holdingPeriod;
  final int holdingYears; // used when period >= 2 years
  final HouseCount houseCount;
  final bool taxExempt; // 1주택 비과세

  // outputs
  final double gain;
  final double longTermDeduction;
  final double basicDeduction;
  final double taxableAmount;
  final double appliedRate;
  final double additionalRatePoints;
  final double incomeTax;
  final double localTax;
  final double totalTax;

  const CapitalGainsTaxState({
    this.sellingPrice = 0,
    this.purchasePrice = 0,
    this.expenses = 0,
    this.holdingPeriod = HoldingPeriod.overTwo,
    this.holdingYears = 3,
    this.houseCount = HouseCount.one,
    this.taxExempt = false,
    this.gain = 0,
    this.longTermDeduction = 0,
    this.basicDeduction = 0,
    this.taxableAmount = 0,
    this.appliedRate = 0,
    this.additionalRatePoints = 0,
    this.incomeTax = 0,
    this.localTax = 0,
    this.totalTax = 0,
  });

  CapitalGainsTaxState copyWith({
    double? sellingPrice,
    double? purchasePrice,
    double? expenses,
    HoldingPeriod? holdingPeriod,
    int? holdingYears,
    HouseCount? houseCount,
    bool? taxExempt,
    double? gain,
    double? longTermDeduction,
    double? basicDeduction,
    double? taxableAmount,
    double? appliedRate,
    double? additionalRatePoints,
    double? incomeTax,
    double? localTax,
    double? totalTax,
  }) =>
      CapitalGainsTaxState(
        sellingPrice: sellingPrice ?? this.sellingPrice,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        expenses: expenses ?? this.expenses,
        holdingPeriod: holdingPeriod ?? this.holdingPeriod,
        holdingYears: holdingYears ?? this.holdingYears,
        houseCount: houseCount ?? this.houseCount,
        taxExempt: taxExempt ?? this.taxExempt,
        gain: gain ?? this.gain,
        longTermDeduction: longTermDeduction ?? this.longTermDeduction,
        basicDeduction: basicDeduction ?? this.basicDeduction,
        taxableAmount: taxableAmount ?? this.taxableAmount,
        appliedRate: appliedRate ?? this.appliedRate,
        additionalRatePoints: additionalRatePoints ?? this.additionalRatePoints,
        incomeTax: incomeTax ?? this.incomeTax,
        localTax: localTax ?? this.localTax,
        totalTax: totalTax ?? this.totalTax,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class CapitalGainsTaxNotifier extends StateNotifier<CapitalGainsTaxState> {
  CapitalGainsTaxNotifier() : super(const CapitalGainsTaxState());

  void setSellingPrice(double v) {
    state = state.copyWith(sellingPrice: v);
    _calculate();
  }

  void setPurchasePrice(double v) {
    state = state.copyWith(purchasePrice: v);
    _calculate();
  }

  void setExpenses(double v) {
    state = state.copyWith(expenses: v);
    _calculate();
  }

  void setHoldingPeriod(HoldingPeriod v) {
    state = state.copyWith(holdingPeriod: v);
    _calculate();
  }

  void setHoldingYears(int v) {
    state = state.copyWith(holdingYears: v);
    _calculate();
  }

  void setHouseCount(HouseCount v) {
    state = state.copyWith(houseCount: v);
    _calculate();
  }

  void setTaxExempt(bool v) {
    state = state.copyWith(taxExempt: v);
    _calculate();
  }

  void _calculate() {
    // 1. 양도차익
    final gain = state.sellingPrice - state.purchasePrice - state.expenses;

    if (gain <= 0) {
      state = state.copyWith(
        gain: gain,
        longTermDeduction: 0,
        basicDeduction: 0,
        taxableAmount: 0,
        appliedRate: 0,
        additionalRatePoints: 0,
        incomeTax: 0,
        localTax: 0,
        totalTax: 0,
      );
      return;
    }

    // 비과세: 1주택 && taxExempt checkbox checked
    if (state.taxExempt && state.houseCount == HouseCount.one) {
      state = state.copyWith(
        gain: gain,
        longTermDeduction: 0,
        basicDeduction: 0,
        taxableAmount: 0,
        appliedRate: 0,
        additionalRatePoints: 0,
        incomeTax: 0,
        localTax: 0,
        totalTax: 0,
      );
      return;
    }

    // 2. 장기보유특별공제 (1주택 + 2년 이상 보유만 적용)
    double longTermDeduction = 0;
    if (state.houseCount == HouseCount.one &&
        state.holdingPeriod == HoldingPeriod.overTwo &&
        state.holdingYears >= 3) {
      final deductionRate = min(state.holdingYears * 2, 30) / 100.0;
      longTermDeduction = gain * deductionRate;
    }

    // 3. 기본공제
    const basicDeduction = 2500000.0;

    // 4. 과세표준
    double taxableAmount = gain - longTermDeduction - basicDeduction;
    if (taxableAmount < 0) taxableAmount = 0;

    // 5. 추가 세율 (다주택 중과)
    double additionalRatePoints = 0;
    if (state.houseCount == HouseCount.two) {
      additionalRatePoints = 20;
    } else if (state.houseCount == HouseCount.threeOrMore) {
      additionalRatePoints = 30;
    }

    // 6. 기본 누진세 계산
    double baseTax = 0;
    double appliedRate = 0;
    if (taxableAmount > 0) {
      for (final bracket in _brackets) {
        if (taxableAmount <= bracket.upperLimit) {
          appliedRate = bracket.rate;
          baseTax =
              taxableAmount * bracket.rate / 100.0 - bracket.progressiveDeduction;
          break;
        }
      }
    }

    // 7. 다주택 중과세 추가분
    double additionalTax = 0;
    if (additionalRatePoints > 0 && taxableAmount > 0) {
      additionalTax = taxableAmount * additionalRatePoints / 100.0;
    }

    final incomeTax = max(baseTax + additionalTax, 0).toDouble();
    final localTax = incomeTax * 0.10;
    final totalTax = incomeTax + localTax;

    state = state.copyWith(
      gain: gain,
      longTermDeduction: longTermDeduction,
      basicDeduction: basicDeduction,
      taxableAmount: taxableAmount,
      appliedRate: appliedRate + additionalRatePoints,
      additionalRatePoints: additionalRatePoints,
      incomeTax: incomeTax,
      localTax: localTax,
      totalTax: totalTax,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final capitalGainsTaxProvider =
    StateNotifierProvider<CapitalGainsTaxNotifier, CapitalGainsTaxState>(
  (ref) => CapitalGainsTaxNotifier(),
);
