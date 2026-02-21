import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/services/notification_service.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class BirthdayEntry {
  final String id;
  final String name;
  final int month;
  final int day;
  final int? year; // optional birth year

  const BirthdayEntry({
    required this.id,
    required this.name,
    required this.month,
    required this.day,
    this.year,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'month': month,
        'day': day,
        if (year != null) 'year': year,
      };

  factory BirthdayEntry.fromJson(Map<String, dynamic> json) => BirthdayEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        month: json['month'] as int,
        day: json['day'] as int,
        year: json['year'] as int?,
      );

  /// Days until next birthday from today.
  int daysUntilNext() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var nextBirthday = DateTime(today.year, month, day);
    if (nextBirthday.isBefore(today)) {
      nextBirthday = DateTime(today.year + 1, month, day);
    }
    return nextBirthday.difference(today).inDays;
  }

  /// Current age (only if birth year is known).
  int? get currentAge {
    if (year == null) return null;
    final now = DateTime.now();
    int age = now.year - year!;
    if (now.month < month || (now.month == month && now.day < day)) {
      age--;
    }
    return age;
  }

  /// Whether today is this person's birthday.
  bool get isBirthdayToday {
    final now = DateTime.now();
    return now.month == month && now.day == day;
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class BirthdayState {
  final List<BirthdayEntry> entries;
  final bool isLoading;

  const BirthdayState({
    this.entries = const [],
    this.isLoading = false,
  });

  BirthdayState copyWith({
    List<BirthdayEntry>? entries,
    bool? isLoading,
  }) =>
      BirthdayState(
        entries: entries ?? this.entries,
        isLoading: isLoading ?? this.isLoading,
      );

  /// Entries sorted by days until next birthday (ascending).
  List<BirthdayEntry> get sortedEntries {
    final sorted = List<BirthdayEntry>.from(entries);
    sorted.sort((a, b) => a.daysUntilNext().compareTo(b.daysUntilNext()));
    return sorted;
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class BirthdayNotifier extends StateNotifier<BirthdayState> {
  static const _storageKey = 'birthdays';
  static const _uuid = Uuid();

  BirthdayNotifier() : super(const BirthdayState(isLoading: true)) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey) ?? '[]';
    final list = (jsonDecode(raw) as List)
        .map((e) => BirthdayEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    state = state.copyWith(entries: list, isLoading: false);

    // Reschedule all notifications on load (no-op on web)
    if (!kIsWeb) {
      NotificationService.rescheduleAll(list);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.entries.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> addEntry({
    required String name,
    required int month,
    required int day,
    int? year,
  }) async {
    final entry = BirthdayEntry(
      id: _uuid.v4(),
      name: name,
      month: month,
      day: day,
      year: year,
    );
    state = state.copyWith(entries: [...state.entries, entry]);
    await _save();

    if (!kIsWeb) {
      await NotificationService.scheduleBirthdayNotifications(entry);
    }
  }

  Future<void> removeEntry(String id) async {
    final updated = state.entries.where((e) => e.id != id).toList();
    state = state.copyWith(entries: updated);
    await _save();

    if (!kIsWeb) {
      await NotificationService.cancelBirthdayNotifications(id);
    }
  }
}

final birthdayProvider =
    StateNotifierProvider<BirthdayNotifier, BirthdayState>(
  (ref) => BirthdayNotifier(),
);
