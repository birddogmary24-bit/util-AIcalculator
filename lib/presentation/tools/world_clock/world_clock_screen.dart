import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/region.dart';
import '../../../providers/region_provider.dart';
import 'world_clock_provider.dart';

final _timeFmt = DateFormat('HH:mm:ss');
final _dateFmtKr = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
final _dateFmtEn = DateFormat('MMM dd, yyyy (E)');

class WorldClockScreen extends ConsumerStatefulWidget {
  const WorldClockScreen({super.key});

  @override
  ConsumerState<WorldClockScreen> createState() => _WorldClockScreenState();
}

class _WorldClockScreenState extends ConsumerState<WorldClockScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tick every second to update clocks
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final state = ref.watch(worldClockProvider);
    final region = ref.watch(regionProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(
            region == RegionMode.kr ? '세계시간' : 'World Clock',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            onPressed: _showAddCitySheet,
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: region == RegionMode.kr ? '도시 추가' : 'Add City',
          ),
        ],
      ),
      body: state.selectedCityIds.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, size: 64,
                      color: cs.onSurfaceVariant.withAlpha(120)),
                  const SizedBox(height: 16),
                  Text(
                    region == RegionMode.kr
                        ? '도시를 추가해 주세요'
                        : 'Please add a city',
                    style: TextStyle(
                      fontSize: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.selectedCityIds.length,
              itemBuilder: (context, index) {
                final cityId = state.selectedCityIds[index];
                final city = getCityById(cityId);
                if (city == null) return const SizedBox.shrink();
                return _CityClockCard(
                  city: city,
                  region: region,
                  onRemove: () {
                    ref
                        .read(worldClockProvider.notifier)
                        .removeCity(cityId);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCitySheet,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: Text(
            region == RegionMode.kr ? '도시 추가' : 'Add City',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showAddCitySheet() {
    final cs = Theme.of(context).colorScheme;
    final state = ref.read(worldClockProvider);
    final region = ref.read(regionProvider);
    final available = state.availableCities;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            region == RegionMode.kr
                ? '모든 도시가 이미 추가되어 있습니다.'
                : 'All cities have already been added.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final sheetCs = Theme.of(context).colorScheme;

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.public, color: sheetCs.primary, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      region == RegionMode.kr ? '도시 선택' : 'Select City',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: sheetCs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: sheetCs.outlineVariant),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final city = available[index];
                    return ListTile(
                      leading: Text(city.emoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(
                        city.displayName(region),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: sheetCs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${city.displayCountry(region)}  ${city.diffText(region)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: sheetCs.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        ref
                            .read(worldClockProvider.notifier)
                            .addCity(city.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── City Clock Card ────────────────────────────────────────────────

class _CityClockCard extends StatelessWidget {
  final CityInfo city;
  final RegionMode region;
  final VoidCallback onRemove;

  const _CityClockCard({
    required this.city,
    required this.region,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = city.currentTime;
    final timeStr = _timeFmt.format(now);
    String dateStr;
    if (region == RegionMode.kr) {
      try {
        dateStr = _dateFmtKr.format(now);
      } catch (_) {
        dateStr = DateFormat('yyyy-MM-dd (E)').format(now);
      }
    } else {
      dateStr = _dateFmtEn.format(now);
    }

    // Determine if it's daytime (06:00 - 18:00)
    final isDaytime = now.hour >= 6 && now.hour < 18;

    return Dismissible(
      key: ValueKey(city.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Left: flag, city name, country
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(city.emoji,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              city.displayName(region),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              city.displayCountry(region),
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    city.diffText(region),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Right: time, date, day/night icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isDaytime ? Icons.wb_sunny : Icons.nightlight_round,
                      color: isDaytime
                          ? const Color(0xFFE8A317)
                          : const Color(0xFF5A6A8A),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                        color: cs.onSurface,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            // Delete button
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close, size: 20),
              color: cs.onSurfaceVariant.withAlpha(150),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
