import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/crypto_price_service.dart';

const coinLabels = <String, String>{
  'bitcoin': 'Bitcoin(BTC)',
  'ethereum': 'Ethereum(ETH)',
  'dogecoin': 'Dogecoin(DOGE)',
};

const coinSymbols = <String, String>{
  'bitcoin': 'BTC',
  'ethereum': 'ETH',
  'dogecoin': 'DOGE',
};

class CryptoState {
  final int tabIndex; // 0: conversion, 1: simulation
  final String selectedCoin; // bitcoin, ethereum, dogecoin
  final double amount;
  final bool isKrwToCoin; // direction
  final double? result;
  final CryptoPrices? prices;
  final bool isLoading;
  final String? error;
  // Simulation fields (BTC only)
  final DateTime? simulationDate;
  final double simulationAmount;
  final double? historicalPrice;
  final double? btcBought;
  final double? currentValue;
  final double? profitPercent;
  final bool isSimulationLoading;
  final String? simulationError;

  const CryptoState({
    this.tabIndex = 0,
    this.selectedCoin = 'bitcoin',
    this.amount = 0,
    this.isKrwToCoin = true,
    this.result,
    this.prices,
    this.isLoading = false,
    this.error,
    this.simulationDate,
    this.simulationAmount = 0,
    this.historicalPrice,
    this.btcBought,
    this.currentValue,
    this.profitPercent,
    this.isSimulationLoading = false,
    this.simulationError,
  });

  CryptoState copyWith({
    int? tabIndex,
    String? selectedCoin,
    double? amount,
    bool? isKrwToCoin,
    double? result,
    CryptoPrices? prices,
    bool? isLoading,
    String? error,
    DateTime? simulationDate,
    double? simulationAmount,
    double? historicalPrice,
    double? btcBought,
    double? currentValue,
    double? profitPercent,
    bool? isSimulationLoading,
    String? simulationError,
  }) =>
      CryptoState(
        tabIndex: tabIndex ?? this.tabIndex,
        selectedCoin: selectedCoin ?? this.selectedCoin,
        amount: amount ?? this.amount,
        isKrwToCoin: isKrwToCoin ?? this.isKrwToCoin,
        result: result ?? this.result,
        prices: prices ?? this.prices,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        simulationDate: simulationDate ?? this.simulationDate,
        simulationAmount: simulationAmount ?? this.simulationAmount,
        historicalPrice: historicalPrice ?? this.historicalPrice,
        btcBought: btcBought ?? this.btcBought,
        currentValue: currentValue ?? this.currentValue,
        profitPercent: profitPercent ?? this.profitPercent,
        isSimulationLoading: isSimulationLoading ?? this.isSimulationLoading,
        simulationError: simulationError,
      );

  /// Current price of the selected coin (from fetched prices).
  double? get currentCoinPrice => prices?.prices[selectedCoin];

  /// Current BTC price for simulation tab.
  double? get currentBtcPrice => prices?.prices['bitcoin'];
}

class CryptoNotifier extends StateNotifier<CryptoState> {
  final CryptoPriceService _service;

  CryptoNotifier(this._service) : super(const CryptoState());

  Future<void> fetchPrices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prices = await _service.getPrices();
      state = state.copyWith(prices: prices, isLoading: false);
      _calculateConversion();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '시세 정보를 불러올 수 없습니다.',
      );
    }
  }

  void setTabIndex(int v) {
    state = state.copyWith(tabIndex: v);
  }

  void setSelectedCoin(String v) {
    state = state.copyWith(selectedCoin: v);
    _calculateConversion();
  }

  void setAmount(double v) {
    state = state.copyWith(amount: v);
    _calculateConversion();
  }

  void toggleDirection() {
    state = state.copyWith(isKrwToCoin: !state.isKrwToCoin);
    _calculateConversion();
  }

  void setSimulationDate(DateTime date) {
    state = state.copyWith(simulationDate: date);
  }

  void setSimulationAmount(double v) {
    state = state.copyWith(simulationAmount: v);
  }

  Future<void> runSimulation() async {
    final date = state.simulationDate;
    if (date == null || state.simulationAmount <= 0) return;

    state = state.copyWith(
      isSimulationLoading: true,
      simulationError: null,
    );

    try {
      final histPrice = await _service.getHistoricalBtcPrice(date);
      final btcAmount = state.simulationAmount / histPrice;

      // Current BTC price
      final currentPrices = state.prices ?? await _service.getPrices();
      final currentBtcPrice = currentPrices.prices['bitcoin'] ?? 0;
      final currentVal = btcAmount * currentBtcPrice;
      final profit = state.simulationAmount > 0
          ? ((currentVal - state.simulationAmount) / state.simulationAmount) *
              100
          : 0.0;

      state = state.copyWith(
        prices: currentPrices,
        historicalPrice: histPrice,
        btcBought: btcAmount,
        currentValue: currentVal,
        profitPercent: profit,
        isSimulationLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSimulationLoading: false,
        simulationError: '과거 시세를 가져올 수 없습니다: $e',
      );
    }
  }

  void _calculateConversion() {
    final price = state.currentCoinPrice;
    if (price == null || state.amount <= 0) {
      state = state.copyWith(result: null);
      return;
    }

    if (state.isKrwToCoin) {
      // KRW -> coin
      state = state.copyWith(result: state.amount / price);
    } else {
      // coin -> KRW
      state = state.copyWith(result: state.amount * price);
    }
  }
}

final cryptoProvider =
    StateNotifierProvider<CryptoNotifier, CryptoState>((ref) {
  final service = ref.watch(cryptoPriceServiceProvider);
  return CryptoNotifier(service);
});
