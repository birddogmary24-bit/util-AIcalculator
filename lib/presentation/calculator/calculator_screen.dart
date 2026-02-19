import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/config_provider.dart';
import '../../providers/theme_provider.dart';
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
        title: const Text('Claude API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI 기능(자연어 계산, 맥락 해석, 스마트 기록)을 사용하려면 Anthropic API 키가 필요합니다.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'sk-ant-...',
                hintText: 'API 키를 입력하세요',
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
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI 계산기',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            tooltip: isDark ? '라이트 모드' : '다크 모드',
          ),
          IconButton(
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _showApiKeyDialog(context, ref),
            tooltip: 'API 키 설정',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              // Display panel
              DisplayPanel(
                display: calcState.display,
                expression: calcState.expression,
                isAiLoading: calcState.isAiLoading,
              ),
              const SizedBox(height: 12),

              // AI Tip Card (animated)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: calcState.showTip && calcState.contextTip != null
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AiTipCard(
                          tip: calcState.contextTip!,
                          onDismiss: () =>
                              ref.read(calculatorProvider.notifier).dismissTip(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // Natural language input bar
              NaturalLangBar(),
              const SizedBox(height: 16),

              // Calculator button grid
              Expanded(
                child: const ButtonGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
