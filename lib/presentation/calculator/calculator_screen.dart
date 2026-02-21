// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../core/constants/region.dart';
import '../../providers/config_provider.dart';
import '../../providers/region_provider.dart';
import '../ai_chat/ai_chat_screen.dart';
import 'calculator_provider.dart';
import 'widgets/display_panel.dart';
import 'widgets/button_grid.dart';

class CalculatorScreen extends ConsumerStatefulWidget {
  const CalculatorScreen({super.key});

  @override
  ConsumerState<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends ConsumerState<CalculatorScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) {
        if (mounted) setState(() => _isListening = false);
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  void _showApiKeyDialog(BuildContext context, Map<String, String> s) {
    final controller = TextEditingController(
      text: ref.read(apiKeyNotifierProvider).valueOrNull ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s['api_key_dialog_title']!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s['api_key_dialog_desc']!,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'AIzaSy...',
                hintText: s['api_key_hint']!,
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s['cancel']!),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await ref.read(apiKeyNotifierProvider.notifier).save(key);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(s['save']!),
          ),
        ],
      ),
    );
  }

  void _showAiChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.85,
          child: const AiChatScreen(),
        ),
      ),
    );
  }

  Future<void> _toggleListening(RegionMode region) async {
    if (!_speechAvailable) return;
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          if (result.finalResult && text.isNotEmpty) {
            setState(() => _isListening = false);
            ref.read(calculatorProvider.notifier).parseNaturalLanguage(text);
          }
        },
        localeId: region == RegionMode.kr ? 'ko_KR' : 'en_US',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: stt.SpeechListenOptions(cancelOnError: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final calcState = ref.watch(calculatorProvider);
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final apiKey = ref.watch(apiKeyNotifierProvider).valueOrNull;
    final hasKey = apiKey != null && apiKey.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.apps),
          onPressed: () => context.push('/tools'),
          tooltip: s['tools_tooltip']!,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        titleSpacing: 4,
        title: Text(
          s['app_title_display']!,
          style: TextStyle(
            fontFamily: region == RegionMode.kr ? 'Pretendard' : null,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: region == RegionMode.kr ? 1.5 : 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_outlined),
            onPressed: () => _showApiKeyDialog(context, s),
            tooltip: s['api_key_tooltip']!,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.history, size: 24),
            onPressed: () => context.push('/history'),
            tooltip: s['history_tooltip']!,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings, size: 22),
              onPressed: () => context.push('/settings'),
              tooltip: s['settings_tooltip']!,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(),
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
                        copyLabel: s['copy']!,
                        copiedLabel: s['copied']!,
                        errorLabel: s['calc_error']!,
                        onAiTap: hasKey ? () => _showAiChat(context) : null,
                        onMicTap: hasKey ? () => _toggleListening(region) : null,
                        isListening: _isListening,
                        speechAvailable: _speechAvailable,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Button grid
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: ButtonGrid(),
            ),
          ],
        ),
      ),
    );
  }
}
