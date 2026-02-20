import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExchangeRates {
  final Map<String, double> rates; // currency code -> rate relative to KRW
  final DateTime fetchedAt;

  const ExchangeRates({required this.rates, required this.fetchedAt});
}

class ExchangeRateService {
  ExchangeRates? _cached;
  static const _cacheDuration = Duration(hours: 1);

  /// Spread for buy/sell rates (approx 1.75%)
  static const _spreadRate = 0.0175;

  Future<ExchangeRates> getRates() async {
    if (_cached != null &&
        DateTime.now().difference(_cached!.fetchedAt) < _cacheDuration) {
      return _cached!;
    }
    // Use open.er-api.com (free, no key required)
    final response = await http.get(
      Uri.parse('https://open.er-api.com/v6/latest/KRW'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final ratesMap = (data['rates'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, (v as num).toDouble()));
      _cached = ExchangeRates(rates: ratesMap, fetchedAt: DateTime.now());
      return _cached!;
    }
    throw Exception('Failed to fetch exchange rates');
  }

  /// Convert amount from one currency to another using the base (standard) rate.
  /// Rates are relative to KRW (1 KRW = X of other currency).
  double convert(ExchangeRates rates, double amount, String from, String to) {
    if (from == to) return amount;
    final fromRate = rates.rates[from] ?? 1.0;
    final toRate = rates.rates[to] ?? 1.0;
    return amount / fromRate * toRate;
  }

  /// Calculate the buy rate (customer buying foreign currency).
  /// buy rate = base rate * (1 + spread)
  double buyRate(double baseRate) => baseRate * (1 + _spreadRate);

  /// Calculate the sell rate (customer selling foreign currency).
  /// sell rate = base rate * (1 - spread)
  double sellRate(double baseRate) => baseRate * (1 - _spreadRate);

  /// Convert with buy/sell spread applied.
  /// [rateType]: 'standard', 'buy', or 'sell'
  double convertWithSpread(
    ExchangeRates rates,
    double amount,
    String from,
    String to,
    String rateType,
  ) {
    if (from == to) return amount;
    final fromRate = rates.rates[from] ?? 1.0;
    final toRate = rates.rates[to] ?? 1.0;
    double baseConversion = amount / fromRate * toRate;

    switch (rateType) {
      case 'buy':
        // Customer buys foreign currency -> more expensive
        return baseConversion * (1 + _spreadRate);
      case 'sell':
        // Customer sells foreign currency -> less favorable
        return baseConversion * (1 - _spreadRate);
      default:
        return baseConversion;
    }
  }
}

final exchangeRateServiceProvider =
    Provider<ExchangeRateService>((ref) => ExchangeRateService());
