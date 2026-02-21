import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/region.dart';
import '../../core/theme/colors.dart';
import '../../providers/region_provider.dart';
import '../../providers/settings_provider.dart';

class RegionSelectScreen extends ConsumerWidget {
  const RegionSelectScreen({super.key});

  void _selectRegion(BuildContext context, WidgetRef ref, RegionMode region) {
    ref.read(regionProvider.notifier).setRegion(region);
    ref.read(settingsProvider.notifier).applyRegionDefaults(region);
    context.go('/');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Title ──────────────────────────────────────────
                Text(
                  '지역을 선택해주세요',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select your region',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '선택에 따라 언어와 기능이 맞춤 설정됩니다',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // ── Region Cards — 항상 2행 1열 ────────────────────
                _RegionCard(
                  emoji: '\u{1F1F0}\u{1F1F7}',
                  title: '한국',
                  subtitle: 'Korea',
                  description: '한국어 UI, 부동산/세금 계산기 포함',
                  onTap: () => _selectRegion(context, ref, RegionMode.kr),
                ),
                const SizedBox(height: 20),
                _RegionCard(
                  emoji: '\u{1F30D}',
                  title: '해외',
                  subtitle: 'Global',
                  description: 'English UI with tip & sales tax tools',
                  onTap: () => _selectRegion(context, ref, RegionMode.global),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Region Card Widget ─────────────────────────────────────────────────────

class _RegionCard extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _RegionCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  State<_RegionCard> createState() => _RegionCardState();
}

class _RegionCardState extends State<_RegionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovering
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.5),
              width: _hovering ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: _hovering ? 16 : 8,
                offset: Offset(0, _hovering ? 6 : 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // 좌측: 이모지
              Text(
                widget.emoji,
                style: const TextStyle(fontSize: 56),
              ),
              const SizedBox(width: 24),

              // 우측: 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // 우측 끝: 화살표 힌트
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary.withValues(alpha: 0.4),
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
