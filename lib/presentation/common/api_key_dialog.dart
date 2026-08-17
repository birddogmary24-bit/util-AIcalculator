import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/config_provider.dart';

void showApiKeyDialog(BuildContext context, WidgetRef ref, Map<String, String> s) {
  final currentKey = ref.read(apiKeyNotifierProvider).valueOrNull ?? '';
  final controller = TextEditingController(text: currentKey);

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(s['api_key_dialog_title'] ?? 'Gemini API 키 설정'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s['api_key_dialog_desc'] ??
                'AI 기능(자연어 계산, 맥락 해석, AI 도우미)을 사용하려면 Google Gemini API 키가 필요합니다.',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'API Key (AIzaSy...)',
              hintText: s['api_key_hint'] ?? 'Gemini API 키를 입력하세요',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        if (currentKey.isNotEmpty)
          TextButton(
            onPressed: () async {
              await ref.read(apiKeyNotifierProvider.notifier).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('키 삭제'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(s['cancel'] ?? '취소'),
        ),
        FilledButton(
          onPressed: () async {
            final key = controller.text.trim();
            if (key.isNotEmpty) {
              await ref.read(apiKeyNotifierProvider.notifier).save(key);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(s['save'] ?? '저장'),
        ),
      ],
    ),
  );
}
