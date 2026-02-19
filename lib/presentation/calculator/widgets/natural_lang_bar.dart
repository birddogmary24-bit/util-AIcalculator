import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/config_provider.dart';
import '../calculator_provider.dart';

class NaturalLangBar extends ConsumerStatefulWidget {
  const NaturalLangBar({super.key});

  @override
  ConsumerState<NaturalLangBar> createState() => _NaturalLangBarState();
}

class _NaturalLangBarState extends ConsumerState<NaturalLangBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(calculatorProvider.notifier).parseNaturalLanguage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyNotifierProvider).valueOrNull;
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    final isLoading = ref.watch(calculatorProvider).isAiLoading;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: hasKey && !isLoading,
            onSubmitted: (_) => _submit(),
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hasKey
                  ? '한국어로 계산하기... (예: 15만원의 10%)'
                  : 'AI 기능을 위해 API 키를 설정하세요',
              hintStyle: const TextStyle(
                color: AppColors.expressionText,
                fontSize: 14,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SendButton(
          enabled: hasKey && !isLoading,
          isLoading: isLoading,
          onTap: _submit,
        ),
      ],
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.expressionText,
          shape: BoxShape.circle,
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}
