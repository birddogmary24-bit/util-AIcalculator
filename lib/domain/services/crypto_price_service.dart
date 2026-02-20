import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CryptoPrices {
  final Map<String, double> prices; // coin id -> KRW price
  final DateTime fetchedAt;

  const CryptoPrices({required this.prices, required this.fetchedAt});
}

class CryptoPriceService {
  CryptoPrices? _cached;
  static const _cacheDuration = Duration(minutes: 2);

  /// Fetch current prices for major coins in KRW.
  Future<CryptoPrices> getPrices() async {
    if (_cached != null &&
        DateTime.now().difference(_cached!.fetchedAt) < _cacheDuration) {
      return _cached!;
    }

    final response = await http.get(Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price'
      '?ids=bitcoin,ethereum,dogecoin&vs_currencies=krw',
    ));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final prices = <String, double>{};
      for (final entry in data.entries) {
        final krwPrice = (entry.value as Map<String, dynamic>)['krw'];
        if (krwPrice != null) {
          prices[entry.key] = (krwPrice as num).toDouble();
        }
      }
      _cached = CryptoPrices(prices: prices, fetchedAt: DateTime.now());
      return _cached!;
    }
    throw Exception('Failed to fetch crypto prices');
  }

  /// Fetch historical BTC price on a given date.
  /// Tries CoinGecko API first, falls back to embedded monthly data.
  Future<double> getHistoricalBtcPrice(DateTime date) async {
    // Try API first
    try {
      final dateStr =
          '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      final response = await http
          .get(
            Uri.parse(
              'https://api.coingecko.com/api/v3/coins/bitcoin/history?date=$dateStr',
            ),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final marketData = data['market_data'];
        if (marketData != null) {
          final currentPrice = marketData['current_price'];
          if (currentPrice != null && currentPrice['krw'] != null) {
            return (currentPrice['krw'] as num).toDouble();
          }
        }
      }
    } catch (_) {
      // Fall through to embedded data
    }

    // Fallback: embedded monthly BTC price table (KRW)
    return _getEmbeddedPrice(date);
  }

  /// Get approximate BTC price from embedded monthly data.
  /// Interpolates between nearest months for dates between data points.
  double _getEmbeddedPrice(DateTime date) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    final price = _historicalBtcKrw[key];
    if (price != null) return price;

    // Find nearest month
    final sorted = _historicalBtcKrw.keys.toList()..sort();
    String? before;
    String? after;
    for (final k in sorted) {
      if (k.compareTo(key) <= 0) before = k;
      if (k.compareTo(key) > 0 && after == null) after = k;
    }

    if (before != null && after != null) {
      // Linear interpolation
      final pBefore = _historicalBtcKrw[before]!;
      final pAfter = _historicalBtcKrw[after]!;
      return (pBefore + pAfter) / 2;
    }

    if (before != null) return _historicalBtcKrw[before]!;
    if (after != null) return _historicalBtcKrw[after]!;

    throw Exception('해당 날짜의 비트코인 시세 데이터가 없습니다.');
  }
}

/// Embedded BTC monthly average prices in KRW.
/// Source: approximate historical data.
const _historicalBtcKrw = <String, double>{
  // 2013
  '2013-01': 15000,
  '2013-04': 150000,
  '2013-07': 100000,
  '2013-10': 200000,
  '2013-12': 1100000,
  // 2014
  '2014-01': 900000,
  '2014-04': 500000,
  '2014-07': 650000,
  '2014-10': 400000,
  '2014-12': 350000,
  // 2015
  '2015-01': 260000,
  '2015-04': 270000,
  '2015-07': 310000,
  '2015-10': 340000,
  '2015-12': 500000,
  // 2016
  '2016-01': 470000,
  '2016-04': 500000,
  '2016-06': 780000,
  '2016-09': 680000,
  '2016-12': 1100000,
  // 2017
  '2017-01': 1200000,
  '2017-03': 1350000,
  '2017-05': 2500000,
  '2017-06': 3200000,
  '2017-08': 5000000,
  '2017-09': 4800000,
  '2017-10': 6500000,
  '2017-11': 10000000,
  '2017-12': 19000000,
  // 2018
  '2018-01': 15000000,
  '2018-02': 10500000,
  '2018-04': 8500000,
  '2018-06': 7500000,
  '2018-09': 7800000,
  '2018-11': 4500000,
  '2018-12': 4200000,
  // 2019
  '2019-01': 4100000,
  '2019-03': 4600000,
  '2019-05': 9600000,
  '2019-06': 13000000,
  '2019-08': 12000000,
  '2019-10': 10000000,
  '2019-12': 8600000,
  // 2020
  '2020-01': 10200000,
  '2020-03': 7800000,
  '2020-05': 11200000,
  '2020-07': 11000000,
  '2020-09': 12500000,
  '2020-10': 15600000,
  '2020-11': 21500000,
  '2020-12': 33000000,
  // 2021
  '2021-01': 37000000,
  '2021-02': 55000000,
  '2021-03': 66000000,
  '2021-04': 72000000,
  '2021-05': 50000000,
  '2021-06': 42000000,
  '2021-07': 38000000,
  '2021-08': 56000000,
  '2021-09': 52000000,
  '2021-10': 73000000,
  '2021-11': 76000000,
  '2021-12': 57000000,
  // 2022
  '2022-01': 50000000,
  '2022-03': 55000000,
  '2022-05': 38000000,
  '2022-06': 26000000,
  '2022-08': 30000000,
  '2022-10': 27000000,
  '2022-11': 22000000,
  '2022-12': 22000000,
  // 2023
  '2023-01': 27000000,
  '2023-03': 36000000,
  '2023-04': 38000000,
  '2023-06': 40000000,
  '2023-09': 35000000,
  '2023-10': 45000000,
  '2023-11': 49000000,
  '2023-12': 56000000,
  // 2024
  '2024-01': 57000000,
  '2024-02': 70000000,
  '2024-03': 93000000,
  '2024-04': 88000000,
  '2024-05': 91000000,
  '2024-06': 85000000,
  '2024-07': 88000000,
  '2024-08': 82000000,
  '2024-09': 85000000,
  '2024-10': 93000000,
  '2024-11': 125000000,
  '2024-12': 135000000,
  // 2025
  '2025-01': 143000000,
  '2025-02': 138000000,
};

final cryptoPriceServiceProvider =
    Provider<CryptoPriceService>((ref) => CryptoPriceService());
