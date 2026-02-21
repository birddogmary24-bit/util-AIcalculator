import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaxPreset {
  final String name;
  final double rate;

  const TaxPreset(this.name, this.rate);
}

const taxPresets = [
  TaxPreset('California', 7.25),
  TaxPreset('New York', 8.0),
  TaxPreset('Texas', 6.25),
  TaxPreset('Florida', 6.0),
  TaxPreset('Illinois', 6.25),
  TaxPreset('No Tax (OR/MT)', 0),
];

class SalesTaxState {
  final double price;
  final double taxRate;
  final String? selectedPreset;
  final double taxAmount;
  final double totalPrice;

  const SalesTaxState({
    this.price = 0,
    this.taxRate = 0,
    this.selectedPreset,
    this.taxAmount = 0,
    this.totalPrice = 0,
  });

  SalesTaxState copyWith({
    double? price,
    double? taxRate,
    String? selectedPreset,
    bool clearPreset = false,
    double? taxAmount,
    double? totalPrice,
  }) =>
      SalesTaxState(
        price: price ?? this.price,
        taxRate: taxRate ?? this.taxRate,
        selectedPreset:
            clearPreset ? null : (selectedPreset ?? this.selectedPreset),
        taxAmount: taxAmount ?? this.taxAmount,
        totalPrice: totalPrice ?? this.totalPrice,
      );
}

class SalesTaxNotifier extends StateNotifier<SalesTaxState> {
  SalesTaxNotifier() : super(const SalesTaxState());

  void setPrice(double v) {
    state = state.copyWith(price: v);
    _calculate();
  }

  void setTaxRate(double v) {
    state = state.copyWith(taxRate: v, clearPreset: true);
    _calculate();
  }

  void selectPreset(TaxPreset preset) {
    state = state.copyWith(
      taxRate: preset.rate,
      selectedPreset: preset.name,
    );
    _calculate();
  }

  void _calculate() {
    final tax = state.price * state.taxRate / 100;
    final total = state.price + tax;
    state = state.copyWith(
      taxAmount: tax,
      totalPrice: total,
    );
  }
}

final salesTaxProvider =
    StateNotifierProvider<SalesTaxNotifier, SalesTaxState>(
  (ref) => SalesTaxNotifier(),
);
