import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/constants/region.dart';
import '../../../core/theme/colors.dart';
import '../../../providers/config_provider.dart';
import '../../../providers/region_provider.dart';
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
        localeId: region == RegionMode.kr ? 'ko_KR' : 'en_US',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        listenOptions: SpeechListenOptions(cancelOnError: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final region = ref.watch(regionProvider);
    final s = AppStrings.of(region);
    final apiKey = ref.watch(apiKeyNotifierProvider).valueOrNull;
    final hasKey = apiKey != null && apiKey.isNotEmpty;
    final isAiLoading = ref.watch(calculatorProvider).isAiLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.background,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: hasKey && !isAiLoading,
              onSubmitted: (_) => _submit(),
              maxLength: 200,
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: hasKey
                    ? (isAiLoading
                        ? s['ai_loading']!
                        : (_isListening ? s['listening']! : s['ask_ai']!))
                    : s['set_api_key_hint']!,
                hintStyle: TextStyle(
                  color: isAiLoading
                      ? AppColors.primary
                      : (_isListening ? AppColors.error : AppColors.expressionText),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppColors.border.withAlpha(120),
                    width: 0.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                isDense: true,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),

          // AI chat button — convex indigo
          GestureDetector(
            onTap: hasKey ? () => _showAiChat(context) : null,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: hasKey
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF7986CB),
                          Color(0xFF3F51B5),
                          Color(0xFF283593),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      )
                    : null,
                color: hasKey ? null : AppColors.expressionText.withAlpha(50),
                shape: BoxShape.circle,
                boxShadow: hasKey
                    ? [
                        BoxShadow(
                          color: const Color(0x66FFFFFF),
                          blurRadius: 3,
                          offset: const Offset(-1, -1),
                        ),
                        BoxShadow(
                          color: const Color(0xAA283593),
                          blurRadius: 8,
                          offset: const Offset(2, 3),
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
              onTap: hasKey ? () => _toggleListening(region) : null,
              gradient: _isListening
                  ? null
                  : (hasKey
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7986CB), Color(0xFF3F51B5), Color(0xFF283593)],
                          stops: [0.0, 0.5, 1.0],
                        )
                      : null),
              color: _isListening
                  ? AppColors.error
                  : AppColors.expressionText.withAlpha(50),
              icon: _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              iconColor: Colors.white,
              iconSize: 22,
              pulse: _isListening,
            ),
          if (_speechAvailable) const SizedBox(width: 8),

          // Send button
          _CircleButton(
            onTap: hasKey && !isAiLoading ? _submit : null,
            gradient: hasKey && !isAiLoading
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7986CB), Color(0xFF3F51B5), Color(0xFF283593)],
                    stops: [0.0, 0.5, 1.0],
                  )
                : null,
            color: AppColors.expressionText.withAlpha(50),
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
                : widget.gradient != null
                    ? [
                        BoxShadow(
                          color: const Color(0x66FFFFFF),
                          blurRadius: 3,
                          offset: const Offset(-1, -1),
                        ),
                        BoxShadow(
                          color: const Color(0xAA283593),
                          blurRadius: 8,
                          offset: const Offset(2, 3),
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
