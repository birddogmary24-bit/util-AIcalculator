import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/region.dart';
import '../../../core/theme/colors.dart';
import '../../../core/utils/number_formatter.dart';
import '../calculator_provider.dart';
import 'mic_button.dart';

class DisplayPanel extends StatefulWidget {
  final String display;
  final String expression;
  final bool isAiLoading;
  final List<DisplayLine> displayHistory;
  final String copyLabel;
  final String copiedLabel;
  final String errorLabel;
  final VoidCallback? onMicTap;
  final VoidCallback? onBackspace;
  final bool isListening;
  final bool speechAvailable;
  final RegionMode region;

  const DisplayPanel({
    super.key,
    required this.display,
    required this.expression,
    this.isAiLoading = false,
    this.displayHistory = const [],
    required this.copyLabel,
    required this.copiedLabel,
    required this.errorLabel,
    this.onMicTap,
    this.onBackspace,
    this.isListening = false,
    this.speechAvailable = false,
    this.region = RegionMode.kr,
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
    if (text.length <= 10) return 46;
    if (text.length <= 14) return 38;
    if (text.length <= 18) return 30;
    return 24;
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
                  // ── Past history lines (컴팩트 1줄 스타일) ─────────────
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.displayHistory.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final line = widget.displayHistory[index];
                        final fmtResult = _formatValue(line.result);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (line.isAi) ...[
                                const _AiBadge(),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  '${_formatExpression(line.expression)} = $fmtResult',
                                  style: const TextStyle(
                                    color: AppColors.lcdExpr,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
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
                      padding: const EdgeInsets.only(bottom: 2),
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

                  // ── Dedicated Main Number Display Row (한 줄 전체 사용) ──
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
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
                              width: 3.5,
                              height: fs * 0.7,
                              margin: const EdgeInsets.only(left: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lcdCursor,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Bottom Control Row: [Mic + Backspace] <---> [AI / Loading / Copy] ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: Mic button + Backspace button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MicButton(
                            speechAvailable: widget.speechAvailable,
                            isListening: widget.isListening,
                            region: widget.region,
                            size: 38,
                            onResult: (_) {},
                            onStart: widget.onMicTap,
                            onStop: widget.onMicTap,
                          ),
                          if (widget.onBackspace != null) ...[
                            const SizedBox(width: 8),
                            _BackspaceButton(
                              size: 38,
                              onTap: widget.onBackspace,
                            ),
                          ],
                        ],
                      ),
                      // Right: AI badge + Loading indicator + Copy button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isCurrentResultAi)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: _AiBadge(large: true),
                            ),
                          if (widget.isAiLoading)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Color(0xFF8A9AB2),
                                ),
                              ),
                            ),
                          _CopyButton(
                            text: formatted,
                            copyLabel: widget.copyLabel,
                            copiedLabel: widget.copiedLabel,
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

class _BackspaceButton extends StatefulWidget {
  final double size;
  final VoidCallback? onTap;

  const _BackspaceButton({
    this.size = 40,
    this.onTap,
  });

  @override
  State<_BackspaceButton> createState() => _BackspaceButtonState();
}

class _BackspaceButtonState extends State<_BackspaceButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7986CB),
                Color(0xFF3F51B5),
                Color(0xFF283593),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: const _ChevronLeftPainter(),
          ),
        ),
      ),
    );
  }
}

class _ChevronLeftPainter extends CustomPainter {
  const _ChevronLeftPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Centered chevron pointing left (<)
    final cx = size.width * 0.44;
    final cy = size.height * 0.5;
    final dx = size.width * 0.14;
    final dy = size.height * 0.18;

    path.moveTo(cx + dx, cy - dy);
    path.lineTo(cx, cy);
    path.lineTo(cx + dx, cy + dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
