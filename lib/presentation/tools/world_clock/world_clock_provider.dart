import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/region.dart';

class CityInfo {
  final String id;
  final String name; // Korean name
  final String nameEn; // English name
  final String country; // Korean country name
  final String countryEn; // English country name
  final Duration utcOffset;
  final String emoji; // flag emoji

  const CityInfo({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.country,
    required this.countryEn,
    required this.utcOffset,
    required this.emoji,
  });

  /// Get display name based on region.
  String displayName(RegionMode region) =>
      region == RegionMode.kr ? name : nameEn;

  /// Get display country based on region.
  String displayCountry(RegionMode region) =>
      region == RegionMode.kr ? country : countryEn;

  /// Current time in this city.
  DateTime get currentTime => DateTime.now().toUtc().add(utcOffset);

  /// Time difference from Seoul in hours (can be fractional).
  double get diffFromSeoul {
    const seoulOffset = Duration(hours: 9);
    return (utcOffset - seoulOffset).inMinutes / 60.0;
  }

  /// Formatted difference string based on region.
  String diffText(RegionMode region) {
    final diff = diffFromSeoul;
    if (region == RegionMode.kr) {
      if (diff == 0) return '서울과 같은 시간';
      final sign = diff > 0 ? '+' : '';
      if (diff == diff.roundToDouble()) {
        return '서울과 $sign${diff.toInt()}시간';
      }
      final hours = diff.truncate();
      final mins = ((diff - hours) * 60).abs().round();
      return '서울과 $sign$hours시간 $mins분';
    } else {
      if (diff == 0) return 'Same as Seoul';
      final sign = diff > 0 ? '+' : '';
      if (diff == diff.roundToDouble()) {
        return 'Seoul $sign${diff.toInt()}h';
      }
      final hours = diff.truncate();
      final mins = ((diff - hours) * 60).abs().round();
      return 'Seoul $sign${hours}h ${mins}m';
    }
  }

  /// Legacy getter for backward compatibility.
  String get diffFromSeoulText => diffText(RegionMode.kr);
}

const allCities = <CityInfo>[
  CityInfo(
      id: 'seoul',
      name: '서울',
      nameEn: 'Seoul',
      country: '대한민국',
      countryEn: 'South Korea',
      utcOffset: Duration(hours: 9),
      emoji: '\u{1F1F0}\u{1F1F7}'),
  CityInfo(
      id: 'tokyo',
      name: '도쿄',
      nameEn: 'Tokyo',
      country: '일본',
      countryEn: 'Japan',
      utcOffset: Duration(hours: 9),
      emoji: '\u{1F1EF}\u{1F1F5}'),
  CityInfo(
      id: 'beijing',
      name: '베이징',
      nameEn: 'Beijing',
      country: '중국',
      countryEn: 'China',
      utcOffset: Duration(hours: 8),
      emoji: '\u{1F1E8}\u{1F1F3}'),
  CityInfo(
      id: 'new_york',
      name: '뉴욕',
      nameEn: 'New York',
      country: '미국',
      countryEn: 'USA',
      utcOffset: Duration(hours: -5),
      emoji: '\u{1F1FA}\u{1F1F8}'),
  CityInfo(
      id: 'los_angeles',
      name: '로스앤젤레스',
      nameEn: 'Los Angeles',
      country: '미국',
      countryEn: 'USA',
      utcOffset: Duration(hours: -8),
      emoji: '\u{1F1FA}\u{1F1F8}'),
  CityInfo(
      id: 'london',
      name: '런던',
      nameEn: 'London',
      country: '영국',
      countryEn: 'UK',
      utcOffset: Duration(hours: 0),
      emoji: '\u{1F1EC}\u{1F1E7}'),
  CityInfo(
      id: 'paris',
      name: '파리',
      nameEn: 'Paris',
      country: '프랑스',
      countryEn: 'France',
      utcOffset: Duration(hours: 1),
      emoji: '\u{1F1EB}\u{1F1F7}'),
  CityInfo(
      id: 'sydney',
      name: '시드니',
      nameEn: 'Sydney',
      country: '호주',
      countryEn: 'Australia',
      utcOffset: Duration(hours: 11),
      emoji: '\u{1F1E6}\u{1F1FA}'),
  CityInfo(
      id: 'dubai',
      name: '두바이',
      nameEn: 'Dubai',
      country: 'UAE',
      countryEn: 'UAE',
      utcOffset: Duration(hours: 4),
      emoji: '\u{1F1E6}\u{1F1EA}'),
  CityInfo(
      id: 'singapore',
      name: '싱가포르',
      nameEn: 'Singapore',
      country: '싱가포르',
      countryEn: 'Singapore',
      utcOffset: Duration(hours: 8),
      emoji: '\u{1F1F8}\u{1F1EC}'),
  CityInfo(
      id: 'bangkok',
      name: '방콕',
      nameEn: 'Bangkok',
      country: '태국',
      countryEn: 'Thailand',
      utcOffset: Duration(hours: 7),
      emoji: '\u{1F1F9}\u{1F1ED}'),
  CityInfo(
      id: 'mumbai',
      name: '뭄바이',
      nameEn: 'Mumbai',
      country: '인도',
      countryEn: 'India',
      utcOffset: Duration(hours: 5, minutes: 30),
      emoji: '\u{1F1EE}\u{1F1F3}'),
  CityInfo(
      id: 'berlin',
      name: '베를린',
      nameEn: 'Berlin',
      country: '독일',
      countryEn: 'Germany',
      utcOffset: Duration(hours: 1),
      emoji: '\u{1F1E9}\u{1F1EA}'),
  CityInfo(
      id: 'moscow',
      name: '모스크바',
      nameEn: 'Moscow',
      country: '러시아',
      countryEn: 'Russia',
      utcOffset: Duration(hours: 3),
      emoji: '\u{1F1F7}\u{1F1FA}'),
  CityInfo(
      id: 'hawaii',
      name: '하와이',
      nameEn: 'Hawaii',
      country: '미국',
      countryEn: 'USA',
      utcOffset: Duration(hours: -10),
      emoji: '\u{1F1FA}\u{1F1F8}'),
];

/// Lookup map for quick city access by id.
final _cityMap = {for (final c in allCities) c.id: c};

CityInfo? getCityById(String id) => _cityMap[id];

class WorldClockState {
  final List<String> selectedCityIds;

  const WorldClockState({
    this.selectedCityIds = const ['seoul', 'new_york', 'london', 'tokyo'],
  });

  WorldClockState copyWith({List<String>? selectedCityIds}) => WorldClockState(
        selectedCityIds: selectedCityIds ?? this.selectedCityIds,
      );

  /// Cities not yet selected (available to add).
  List<CityInfo> get availableCities =>
      allCities.where((c) => !selectedCityIds.contains(c.id)).toList();
}

class WorldClockNotifier extends StateNotifier<WorldClockState> {
  WorldClockNotifier() : super(const WorldClockState());

  void addCity(String cityId) {
    if (state.selectedCityIds.contains(cityId)) return;
    state = state.copyWith(
      selectedCityIds: [...state.selectedCityIds, cityId],
    );
  }

  void removeCity(String cityId) {
    state = state.copyWith(
      selectedCityIds:
          state.selectedCityIds.where((id) => id != cityId).toList(),
    );
  }

  void reorderCities(int oldIndex, int newIndex) {
    final ids = [...state.selectedCityIds];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    state = state.copyWith(selectedCityIds: ids);
  }
}

final worldClockProvider =
    StateNotifierProvider<WorldClockNotifier, WorldClockState>(
  (ref) => WorldClockNotifier(),
);
