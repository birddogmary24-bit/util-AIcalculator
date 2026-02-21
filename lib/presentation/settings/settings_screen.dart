import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/region.dart';
import '../../providers/button_config_provider.dart';
import '../../providers/region_provider.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          s['settings_title']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          // ── Region Section ──────────────────────────────────────────
          _SectionHeader(title: s['region_title']!),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.public,
            label: s['region_title']!,
            child: _DropdownTile<RegionMode>(
              value: region,
              items: [
                _DropdownItem(RegionMode.kr, s['region_kr']!),
                _DropdownItem(RegionMode.global, s['region_global']!),
              ],
              onChanged: (v) => _confirmRegionChange(context, ref, region, v, s),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Language & Display Section ──────────────────────────────
          const SizedBox(height: 8),
          _SectionHeader(title: s['language_title']!),
          const SizedBox(height: 12),

          // Default Currency
          _SettingsRow(
            icon: Icons.attach_money,
            label: s['currency_title']!,
            child: _DropdownTile<AppCurrency>(
              value: settings.currency,
              items: const [
                _DropdownItem(AppCurrency.krw, '\u20A9 KRW'),
                _DropdownItem(AppCurrency.usd, '\$ USD'),
                _DropdownItem(AppCurrency.eur, '\u20AC EUR'),
                _DropdownItem(AppCurrency.gbp, '\u00A3 GBP'),
              ],
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setCurrency(v),
            ),
          ),
          const SizedBox(height: 16),

          // Unit System
          _SettingsRow(
            icon: Icons.straighten,
            label: s['units_title']!,
            child: _DropdownTile<UnitSystem>(
              value: settings.units,
              items: [
                _DropdownItem(UnitSystem.metric, s['units_metric']!),
                _DropdownItem(UnitSystem.imperial, s['units_imperial']!),
              ],
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setUnits(v),
            ),
          ),
          const SizedBox(height: 16),

          // Date Format
          _SettingsRow(
            icon: Icons.calendar_today,
            label: s['date_format_title']!,
            child: _DropdownTile<DateFormatOption>(
              value: settings.dateFormat,
              items: const [
                _DropdownItem(DateFormatOption.yyyymmdd, 'YYYY.MM.DD'),
                _DropdownItem(DateFormatOption.mmddyyyy, 'MM/DD/YYYY'),
                _DropdownItem(DateFormatOption.ddmmyyyy, 'DD/MM/YYYY'),
              ],
              onChanged: (v) =>
                  ref.read(settingsProvider.notifier).setDateFormat(v),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // ── Other Section ──────────────────────────────────────────
          const SizedBox(height: 8),
          _SectionHeader(
            title: region == RegionMode.kr ? '기타' : 'Other',
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.restart_alt,
            label: s['reset_layout_title']!,
            subtitle: s['reset_layout_desc'],
            onTap: () => _confirmReset(context, ref, s),
          ),
        ],
      ),
    );
  }

  void _confirmRegionChange(
    BuildContext context,
    WidgetRef ref,
    RegionMode currentRegion,
    RegionMode newRegion,
    Map<String, String> s,
  ) {
    if (newRegion == currentRegion) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['region_change_title']!),
        content: Text(s['region_change_desc']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s['cancel']!),
          ),
          FilledButton(
            onPressed: () {
              ref.read(regionProvider.notifier).setRegion(newRegion);
              ref.read(settingsProvider.notifier).applyRegionDefaults(newRegion);
              Navigator.pop(ctx);
            },
            child: Text(s['confirm']!),
          ),
        ],
      ),
    );
  }

  void _confirmReset(
    BuildContext context,
    WidgetRef ref,
    Map<String, String> s,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['reset_layout_title']!),
        content: Text(s['reset_confirm']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s['cancel']!),
          ),
          FilledButton(
            onPressed: () {
              ref.read(buttonConfigProvider.notifier).resetToDefault();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s['reset_done']!)),
              );
            },
            child: Text(s['reset']!),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Settings Row ────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? child;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (child != null) child!,
            if (onTap != null && child == null)
              const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown Tile ───────────────────────────────────────────────────────────

class _DropdownItem<T> {
  final T value;
  final String label;
  const _DropdownItem(this.value, this.label);
}

class _DropdownTile<T> extends StatelessWidget {
  final T value;
  final List<_DropdownItem<T>> items;
  final ValueChanged<T> onChanged;

  const _DropdownTile({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentLabel =
        items.firstWhere((i) => i.value == value).label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: PopupMenuButton<T>(
        onSelected: onChanged,
        offset: const Offset(0, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        itemBuilder: (_) => items
            .map((item) => PopupMenuItem<T>(
                  value: item.value,
                  child: Row(
                    children: [
                      if (item.value == value)
                        const Icon(Icons.check, size: 18, color: Colors.indigo)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: item.value == value
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more, size: 20, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
