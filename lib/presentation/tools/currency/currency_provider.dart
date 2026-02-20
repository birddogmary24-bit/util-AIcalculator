import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/exchange_rate_service.dart';

enum RateType { standard, buy, sell }

const currencyLabels = <String, String>{
  'KRW': '원화(KRW)',
  'USD': '미국 달러(USD)',
  'EUR': '유로(EUR)',
  'JPY': '일본 엔(JPY)',
  'CNY': '중국 위안(CNY)',
  'GBP': '영국 파운드(GBP)',
};

class CurrencyState {
  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final RateType rateType;
  final double? result;
  final double? appliedRate;
  final ExchangeRates? rates;
  final bool isLoading;
  final String? error;

  const CurrencyState({
    this.amount = 0,
    this.fromCurrency = 'KRW',
    this.toCurrency = 'USD',
    this.rateType = RateType.standard,
    this.result,
    this.appliedRate,
    this.rates,
    this.isLoading = false,
    this.error,
  });

  CurrencyState copyWith({
    double? amount,
    String? fromCurrency,
    String? toCurrency,
    RateType? rateType,
    double? result,
    double? appliedRate,
    ExchangeRates? rates,
    bool? isLoading,
    String? error,
  }) =>
      CurrencyState(
        amount: amount ?? this.amount,
        fromCurrency: fromCurrency ?? this.fromCurrency,
        toCurrency: toCurrency ?? this.toCurrency,
        rateType: rateType ?? this.rateType,
        result: result ?? this.result,
        appliedRate: appliedRate ?? this.appliedRate,
        rates: rates ?? this.rates,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// Last updated time as formatted string.
  String get lastUpdatedText {
    if (rates == null) return '';
    final t = rates!.fetchedAt;
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final ExchangeRateService _service;

  CurrencyNotifier(this._service) : super(const CurrencyState());

  Future<void> fetchRates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rates = await _service.getRates();
      state = state.copyWith(rates: rates, isLoading: false);
      _calculate();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '환율 정보를 불러올 수 없습니다.',
      );
    }
  }

  void setAmount(double v) {
    state = state.copyWith(amount: v);
    _calculate();
  }

  void setFromCurrency(String v) {
    state = state.copyWith(fromCurrency: v);
    _calculate();
  }

  void setToCurrency(String v) {
    state = state.copyWith(toCurrency: v);
    _calculate();
  }

  void setRateType(RateType v) {
    state = state.copyWith(rateType: v);
    _calculate();
  }

  void swapCurrencies() {
    state = state.copyWith(
      fromCurrency: state.toCurrency,
      toCurrency: state.fromCurrency,
    );
    _calculate();
  }

  void _calculate() {
    final rates = state.rates;
    if (rates == null || state.amount <= 0) {
      state = state.copyWith(result: null, appliedRate: null);
      return;
    }

    final rateTypeStr = switch (state.rateType) {
      RateType.standard => 'standard',
      RateType.buy => 'buy',
      RateType.sell => 'sell',
    };

    final result = _service.convertWithSpread(
      rates,
      state.amount,
      state.fromCurrency,
      state.toCurrency,
      rateTypeStr,
    );

    // Calculate applied rate (1 unit of fromCurrency in toCurrency)
    final unitRate = _service.convertWithSpread(
      rates,
      1,
      state.fromCurrency,
      state.toCurrency,
      rateTypeStr,
    );

    state = state.copyWith(result: result, appliedRate: unitRate);
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final service = ref.watch(exchangeRateServiceProvider);
  return CurrencyNotifier(service);
});
