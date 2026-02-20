import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/config_provider.dart';
import 'calculator_provider.dart';
import 'widgets/display_panel.dart';
import 'widgets/button_grid.dart';
import 'widgets/ai_tip_card.dart';
import 'widgets/natural_lang_bar.dart';

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  void _showApiKeyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(apiKeyNotifierProvider).valueOrNull ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 기능(자연어 계산, 맥락 해석, 스마트 기록)을 사용하려면 Google Gemini API 키가 필요합니다.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'AIzaSy...',
                hintText: 'Gemini API 키를 입력하세요',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await ref.read(apiKeyNotifierProvider.notifier).save(key);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calcState = ref.watch(calculatorProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.apps),
          onPressed: () => context.push('/tools'),
          tooltip: '도구 모음',
        ),
        titleSpacing: 4,
        title: const Text(
          '알뜰계산기.AI',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 23,
            letterSpacing: 2.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            onPressed: () => context.push('/settings'),
            tooltip: '설정',
          ),
          IconButton(
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _showApiKeyDialog(context, ref),
            tooltip: 'API 키 설정',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.history, size: 28),
              onPressed: () => context.push('/history'),
              tooltip: '기록',
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display area — expands to fill remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: DisplayPanel(
                        display: calcState.display,
                        expression: calcState.expression,
                        isAiLoading: calcState.isAiLoading,
                        displayHistory: calcState.displayHistory,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // AI Tip Card (animated)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: calcState.showTip && calcState.contextTip != null
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: AiTipCard(
                                tip: calcState.contextTip!,
                                onDismiss: () =>
                                    ref.read(calculatorProvider.notifier).dismissTip(),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Button grid
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: ButtonGrid(),
            ),

            const SizedBox(height: 8),

            // Natural language input bar
            const NaturalLangBar(),
          ],
        ),
      ),
    );
  }
}
