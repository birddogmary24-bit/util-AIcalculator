import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../calculator_provider.dart';

class DisplayPanel extends StatefulWidget {
  final String display;
  final String expression;
  final bool isAiLoading;
  final List<DisplayLine> displayHistory;
  final String copyLabel;
  final String copiedLabel;
  final String errorLabel;
  final VoidCallback? onAiTap;
  final VoidCallback? onMicTap;
  final bool isListening;
  final bool speechAvailable;

  const DisplayPanel({
    super.key,
    required this.display,
    required this.expression,
    this.isAiLoading = false,
    this.displayHistory = const [],
    required this.copyLabel,
    required this.copiedLabel,
    required this.errorLabel,
    this.onAiTap,
    this.onMicTap,
    this.isListening = false,
    this.speechAvailable = false,
  });

  @override
  State<DisplayPanel> createState() => _DisplayPanelState();
}

class _DisplayPanelState extends State<DisplayPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late Animation<double> _cursorAnim;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _cursorAnim = CurvedAnimation(
      parent: _cursorController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant DisplayPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newHistory = widget.displayHistory;
    final oldHistory = oldWidget.displayHistory;
    final shouldScroll = newHistory.isNotEmpty &&
        (newHistory.length != oldHistory.length ||
            (oldHistory.isNotEmpty &&
                newHistory.last.expression != oldHistory.last.expression));
    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _cursorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isIdle =>
      widget.display == '0' &&
      widget.expression.isEmpty &&
      !widget.isAiLoading;

  bool get _isCurrentResultAi {
    final h = widget.displayHistory;
    return h.isNotEmpty &&
        h.last.isAi &&
        h.last.result == widget.display;
  }

  String _formatValue(String raw) {
    if (raw == widget.errorLabel) return raw;
    if (raw == '계산 오류') return raw;
    final num = double.tryParse(raw);
    if (num != null) return NumberFormatter.format(num);
    return NumberFormatter.formatDisplay(raw);
  }

  String _formatExpression(String expr) {
    return expr.replaceAllMapped(
      RegExp(r'-?\d+(\.\d+)?'),
      (m) {
        final raw = m.group(0)!;
        final num = double.tryParse(raw);
        if (num == null) return raw;
        return NumberFormatter.format(num);
      },
    );
  }

  double _fontSize(String text) {
    if (text.length <= 6) return 52;
    if (text.length <= 9) return 42;
    if (text.length <= 12) return 34;
    return 26;
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _formatValue(widget.display);
    final fs = _fontSize(formatted);

    // Outer bezel — dark frame (reduced margin for thinner appearance)
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lcdBezel,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // LCD screen area (reduced margin = thinner bezel appearance)
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.lcdBg,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Past history lines (scrollable) ──────────────────
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.displayHistory.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final line = widget.displayHistory[index];
                        final fmtResult = _formatValue(line.result);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatExpression(line.expression),
                                style: const TextStyle(
                                  color: AppColors.lcdExpr,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (line.isAi) ...[
                                    const _AiBadge(),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      '= $fmtResult',
                                      style: const TextStyle(
                                        color: AppColors.lcdText,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(
                                height: 8,
                                thickness: 0.5,
                                color: AppColors.lcdExpr,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Current expression ───────────────────────────────
                  if (widget.expression.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        _formatExpression(widget.expression),
                        style: const TextStyle(
                          color: AppColors.lcdExpr,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),

                  // ── Bottom row: [AI][Mic] left | [Copy] [Number][Cursor] right ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // AI button (leftmost)
                      GestureDetector(
                        onTap: widget.onAiTap,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: widget.onAiTap != null
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
                            color: widget.onAiTap == null
                                ? AppColors.expressionText.withAlpha(50)
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: widget.onAiTap != null
                                ? [
                                    const BoxShadow(
                                      color: Color(0x66FFFFFF),
                                      blurRadius: 3,
                                      offset: Offset(-1, -1),
                                    ),
                                    const BoxShadow(
                                      color: Color(0xAA283593),
                                      blurRadius: 8,
                                      offset: Offset(2, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      // Mic button (right of AI)
                      if (widget.speechAvailable) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: widget.onMicTap,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: !widget.isListening && widget.onMicTap != null
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
                              color: widget.isListening
                                  ? AppColors.error
                                  : (widget.onMicTap == null
                                      ? AppColors.expressionText.withAlpha(50)
                                      : null),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              widget.isListening
                                  ? Icons.stop_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                      // Spacer pushes the right side to the end
                      const Spacer(),
                      // Copy button (just left of number)
                      _CopyButton(
                        text: formatted,
                        copyLabel: widget.copyLabel,
                        copiedLabel: widget.copiedLabel,
                      ),
                      const SizedBox(width: 6),
                      if (_isCurrentResultAi)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: _AiBadge(large: true),
                        ),
                      if (widget.isAiLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Color(0xFF8A9AB2),
                            ),
                          ),
                        ),
                      // Number + cursor (rightmost)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 200),
                            child: Text(
                              formatted,
                              style: TextStyle(
                                color: AppColors.lcdText,
                                fontSize: fs,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -1,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          if (_isIdle)
                            FadeTransition(
                              opacity: _cursorAnim,
                              child: Container(
                                width: 3,
                                height: fs * 0.7,
                                margin: const EdgeInsets.only(left: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.lcdCursor,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Bottom bezel space
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  final String copyLabel;
  final String copiedLabel;

  const _CopyButton({
    required this.text,
    required this.copyLabel,
    required this.copiedLabel,
  });

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _copy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _copied
              ? AppColors.lcdCursor.withAlpha(60)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.lcdExpr.withAlpha(100),
            width: 1,
          ),
        ),
        child: Text(
          _copied ? widget.copiedLabel : widget.copyLabel,
          style: const TextStyle(
            color: AppColors.lcdExpr,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  final bool large;
  const _AiBadge({this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 11.0 : 9.0;
    final pad = large
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 4, vertical: 1);
    return Container(
      padding: pad,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'AI',
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
