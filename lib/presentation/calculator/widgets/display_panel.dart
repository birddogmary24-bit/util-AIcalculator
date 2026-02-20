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

  const DisplayPanel({
    super.key,
    required this.display,
    required this.expression,
    this.isAiLoading = false,
    this.displayHistory = const [],
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
    // Auto-scroll to bottom when new history is added
    if (widget.displayHistory.length > oldWidget.displayHistory.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
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

  String _formatValue(String raw) {
    if (raw == '계산 오류') return raw;
    final num = double.tryParse(raw);
    if (num != null) return NumberFormatter.format(num);
    return NumberFormatter.formatDisplay(raw);
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

    // Outer bezel — dark frame
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
          // Bezel top label strip
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'AI CALCULATOR',
                  style: TextStyle(
                    color: Color(0xFF6A6E80),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                if (widget.isAiLoading)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Color(0xFF8A9AB2),
                    ),
                  ),
              ],
            ),
          ),

          // LCD screen area
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.lcdBg,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
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
                                line.expression,
                                style: const TextStyle(
                                  color: AppColors.lcdExpr,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                              ),
                              Text(
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
                        widget.expression,
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

                  // ── Current result (large) ───────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
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
                      ),
                      const SizedBox(width: 6),
                      _CopyButton(text: formatted),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String text;
  const _CopyButton({required this.text});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
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
          _copied ? '복사됨' : '복사',
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
