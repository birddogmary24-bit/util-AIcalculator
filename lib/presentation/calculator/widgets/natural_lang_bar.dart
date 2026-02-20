import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/config_provider.dart';
import '../calculator_provider.dart';
import '../../ai_chat/ai_chat_screen.dart';

class NaturalLangBar extends ConsumerStatefulWidget {
  const NaturalLangBar({super.key});

  @override
  ConsumerState<NaturalLangBar> createState() => _NaturalLangBarState();
}

class _NaturalLangBarState extends ConsumerState<NaturalLangBar> {
  final _controller = TextEditingController();
  final _speech = SpeechToText();
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
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(calculatorProvider.notifier).parseNaturalLanguage(text);
    _controller.clear();
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

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          final text = result.recognizedWords;
          if (text.isNotEmpty) {
            _controller.text = text;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          }
          // Auto-submit on final result
          if (result.finalResult && text.isNotEmpty) {
            setState(() => _isListening = false);
            Future.delayed(const Duration(milliseconds: 300), _submit);
          }
        },
        localeId: 'ko_KR',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(cancelOnError: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = ref.watch(apiKeyNotifierProvider).valueOrNull;
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    final isAiLoading = ref.watch(calculatorProvider).isAiLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: hasKey && !isAiLoading,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: hasKey
                    ? (_isListening ? '듣고 있습니다...' : 'AI한테 물어서 계산하세요')
                    : 'AI 기능을 위해 API 키를 설정하세요',
                hintStyle: TextStyle(
                  color: _isListening ? AppColors.error : AppColors.expressionText,
                  fontSize: 14,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // AI chat button — gradient
          GestureDetector(
            onTap: hasKey ? () => _showAiChat(context) : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: hasKey
                    ? const LinearGradient(
                        colors: [Color(0xFF4E8AFF), Color(0xFF9B6DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasKey ? null : AppColors.expressionText.withAlpha(50),
                shape: BoxShape.circle,
                boxShadow: hasKey
                    ? [
                        BoxShadow(
                          color: const Color(0xFF6B7FFF).withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Mic button
          if (_speechAvailable)
            _CircleButton(
              onTap: hasKey ? _toggleListening : null,
              gradient: _isListening
                  ? null
                  : (hasKey ? const LinearGradient(colors: [Color(0xFF5A5E6B), Color(0xFF3A3E4B)]) : null),
              color: _isListening
                  ? AppColors.error
                  : (hasKey ? AppColors.operatorBtn : AppColors.expressionText.withAlpha(50)),
              icon: _isListening
                  ? Icons.stop_rounded
                  : Icons.mic_rounded,
              iconColor: Colors.white,
              iconSize: 22,
              pulse: _isListening,
            ),
          if (_speechAvailable) const SizedBox(width: 8),

          // Send button
          _CircleButton(
            onTap: hasKey && !isAiLoading ? _submit : null,
            color: hasKey && !isAiLoading
                ? AppColors.primary
                : AppColors.expressionText.withAlpha(50),
            icon: isAiLoading ? null : Icons.arrow_upward_rounded,
            iconColor: Colors.white,
            iconSize: 22,
            isLoading: isAiLoading,
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;
  final Gradient? gradient;
  final IconData? icon;
  final Color iconColor;
  final double iconSize;
  final bool isLoading;
  final bool pulse;

  const _CircleButton({
    required this.onTap,
    required this.color,
    this.gradient,
    this.icon,
    required this.iconColor,
    this.iconSize = 20,
    this.isLoading = false,
    this.pulse = false,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_CircleButton old) {
    super.didUpdateWidget(old);
    if (widget.pulse && !old.pulse) {
      _pulse.repeat(reverse: true);
    } else if (!widget.pulse && old.pulse) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            color: widget.gradient == null ? widget.color : null,
            shape: BoxShape.circle,
            boxShadow: widget.pulse
                ? [
                    BoxShadow(
                      color: AppColors.error.withAlpha(80),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: widget.isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(widget.icon, color: widget.iconColor, size: widget.iconSize),
        ),
      ),
    );
  }
}
