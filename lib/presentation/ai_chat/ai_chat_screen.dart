import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/region.dart';
import '../../core/theme/colors.dart';
import '../../domain/services/proxy_ai_service.dart';
import '../../domain/services/usage_limiter.dart';
import '../../providers/config_provider.dart';
import '../../providers/region_provider.dart';
import '../calculator/calculator_provider.dart';

// --- State ---

class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime time;
  final bool isSystem;

  const ChatMessage({
    required this.role,
    required this.content,
    required this.time,
    this.isSystem = false,
  });
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const AiChatState({this.messages = const [], this.isLoading = false});

  AiChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return AiChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref _ref;

  AiChatNotifier(this._ref) : super(const AiChatState()) {
    _initWelcome();
  }

  void _initWelcome() {
    final region = _ref.read(regionProvider);
    final s = AppStrings.of(region);
    state = AiChatState(messages: [
      ChatMessage(
        role: 'assistant',
        content: s['chat_welcome']!,
        time: DateTime.now(),
        isSystem: true,
      ),
    ]);
  }

  Future<void> send(String input) async {
    if (input.trim().isEmpty) return;
    final service = _ref.read(aiServiceProvider);
    if (service == null) return;

    final userMsg = ChatMessage(
      role: 'user',
      content: input.trim(),
      time: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      await _ref.read(usageLimiterProvider).checkAndIncrement();

      final history = state.messages
          .where((m) => !m.isSystem)
          .map((m) => {'role': m.role, 'content': m.content})
          .toList();

      final reply = await service.chat(history);
      final aiMsg = ChatMessage(
        role: 'assistant',
        content: reply,
        time: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } on LimitExceededException {
      final region = _ref.read(regionProvider);
      final s = AppStrings.of(region);
      final errMsg = ChatMessage(
        role: 'assistant',
        content: s['ai_limit_reached']!,
        time: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errMsg],
        isLoading: false,
      );
    } catch (e) {
      final region = _ref.read(regionProvider);
      final s = AppStrings.of(region);
      final errMsg = ChatMessage(
        role: 'assistant',
        content: s['chat_error']!,
        time: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errMsg],
        isLoading: false,
      );
    }
  }

  void clear() {
    final region = _ref.read(regionProvider);
    final s = AppStrings.of(region);
    state = AiChatState(messages: [
      ChatMessage(
        role: 'assistant',
        content: s['chat_reset_msg']!,
        time: DateTime.now(),
        isSystem: true,
      ),
    ]);
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});

// --- UI ---

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(aiChatProvider.notifier).send(text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(ref.watch(regionProvider));
    final chatState = ref.watch(aiChatProvider);
    final service = ref.watch(aiServiceProvider);
    final hasKey = service != null;
    final remaining = (service is ProxyAiService) ? service.remainingToday : -1;

    // Auto scroll on new message
    ref.listen(aiChatProvider, (_, __) {
      Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          s['ai_assistant']!,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (chatState.messages.length > 1)
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () => ref.read(aiChatProvider.notifier).clear(),
              tooltip: s['reset_chat']!,
            ),
        ],
      ),
      body: Column(
        children: [
          _policyBar(context, s, remaining),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chatState.messages.length +
                  (chatState.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == chatState.messages.length) {
                  return _TypingIndicator();
                }
                final msg = chatState.messages[index];
                return _ChatBubble(
                  message: msg,
                  toCalculatorText: s['to_calculator']!,
                );
              },
            ),
          ),

          // Input bar
          _ChatInputBar(
            controller: _controller,
            enabled: hasKey && !chatState.isLoading,
            onSend: _send,
            hintEnabled: s['chat_input_hint']!,
            hintDisabled: s['set_api_first']!,
          ),
        ],
      ),
    );
  }

  /// 정책 안내 + 사용량 표시 바 (항상 노출)
  Widget _policyBar(BuildContext context, Map<String, String> s, int remaining) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final region = ref.watch(regionProvider);
    final isKr = region == RegionMode.kr;

    final policyText = isKr
        ? '하루 50회 무료 제공 · 개인정보 미수집'
        : 'Free 50 uses/day · No personal data collected';

    final countText = remaining >= 0
        ? (isKr ? '오늘 남은 횟수  $remaining / 50' : 'Remaining today  $remaining / 50')
        : (isKr ? '오늘 남은 횟수  — / 50' : 'Remaining today  — / 50');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withAlpha(10)
            : Colors.black.withAlpha(6),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              policyText,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          Text(
            countText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: remaining == 0
                  ? AppColors.error
                  : (isDark ? Colors.white54 : Colors.black45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends ConsumerWidget {
  final ChatMessage message;
  final String toCalculatorText;

  const _ChatBubble({
    required this.message,
    required this.toCalculatorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUser = message.role == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.aiTipAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (isDark
                            ? const Color(0xFF2C2C2E)
                            : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                // "To Calculator" button for AI messages with numbers
                if (!isUser && _hasNumber(message.content))
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _SendToCalcButton(
                      content: message.content,
                      ref: ref,
                      label: toCalculatorText,
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  bool _hasNumber(String text) {
    return RegExp(r'\d').hasMatch(text);
  }
}

class _SendToCalcButton extends StatelessWidget {
  final String content;
  final WidgetRef ref;
  final String label;

  const _SendToCalcButton({
    required this.content,
    required this.ref,
    required this.label,
  });

  double? _extractLastNumber(String text) {
    final matches = RegExp(r'[\d,]+\.?\d*').allMatches(text);
    if (matches.isEmpty) return null;
    final raw = matches.last.group(0)!.replaceAll(',', '');
    return double.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final num = _extractLastNumber(content);
        if (num != null) {
          ref.read(calculatorProvider.notifier).loadFromHistory(content, num);
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withAlpha(80)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calculate_outlined, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.aiTipAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Dot(delay: 0),
                  _Dot(delay: 200),
                  _Dot(delay: 400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.expressionText,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final String hintEnabled;
  final String hintDisabled;

  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
    required this.hintEnabled,
    required this.hintDisabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                maxLength: 200,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: enabled ? hintEnabled : hintDisabled,
                  hintStyle: const TextStyle(
                    color: AppColors.expressionText,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  isDense: true,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: enabled ? AppColors.primary : AppColors.expressionText,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
