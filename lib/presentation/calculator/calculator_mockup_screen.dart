import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalculatorMockupScreen extends StatefulWidget {
  const CalculatorMockupScreen({super.key});

  @override
  State<CalculatorMockupScreen> createState() => _CalculatorMockupScreenState();
}

class _CalculatorMockupScreenState extends State<CalculatorMockupScreen> {
  @override
  Widget build(BuildContext context) {
    // Determine screen width to ensure we don't exceed 430px
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 430;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E0D4), // Warm beige plastic body
      body: Center(
        child: Container(
          width: 430,
          height: isLargeScreen ? 932 : null, // iPhone 14 Pro Height approx
          decoration: BoxDecoration(
            color: const Color(0xFFE8E0D4),
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF2EBE0), // Lighter cream at top
                Color(0xFFE0D8CC), // Slightly darker at bottom
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top Label
                      _buildTopLabel(),
                      const SizedBox(height: 20),

                      // LCD Display
                      _buildLCDDisplay(),
                      const SizedBox(height: 16),

                      // AI Tip Card
                      _buildAITipCard(),
                      const SizedBox(height: 24),

                      // Buttons
                      Expanded(child: _buildButtonGrid()),

                      // Input Bar
                      _buildInputBar(),
                    ],
                  ),
                ),
              ),

              // Bottom Navigation Bar
              _buildBottomNavigationBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopLabel() {
    return Text(
      'AI CALCULATOR',
      style: TextStyle(
        fontFamily: 'Inter', // Fallback
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF8A8578).withOpacity(0.7),
        letterSpacing: 1.5,
        shadows: [
          Shadow(
            color: Colors.white.withOpacity(0.8),
            offset: const Offset(-1, -1),
            blurRadius: 1,
          ),
          Shadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLCDDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFC8D8B0), // Green-tinted LCD
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8A8578), // Dark gray bezel
          width: 8,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x40000000), // Shadow color at top
            Colors.transparent, // Fade out
          ],
          stops: [0.0, 0.15],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '250,000 × 50%',
            style: GoogleFonts.robotoMono(
              fontSize: 16,
              color: const Color(0xFF333A2F).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '125,000',
            style: GoogleFonts.vt323(
              // Or generic monospace if not available
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1F18), // Dark green-black
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITipCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5E8), // Light green background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6B8E5A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '팁: 25만원의 절반이에요',
              style: TextStyle(
                fontSize: 14,
                color: const Color(0xFF4A5F40),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Column(
      children: [
        _buildButtonRow([
          'AC',
          '+/-',
          '%',
          '÷'
        ], colors: [
          const Color(0xFFB8B0A4),
          const Color(0xFFB8B0A4),
          const Color(0xFFB8B0A4),
          const Color(0xFFE8A44C)
        ]),
        const SizedBox(height: 16),
        _buildButtonRow(['7', '8', '9', '×']),
        const SizedBox(height: 16),
        _buildButtonRow(['4', '5', '6', '−']),
        const SizedBox(height: 16),
        _buildButtonRow(['1', '2', '3', '+']),
        const SizedBox(height: 16),
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildButtonRow(List<String> labels, {List<Color>? colors}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(labels.length, (index) {
        final label = labels[index];
        final isOperator = ['÷', '×', '−', '+', '='].contains(label);
        final isTop = ['AC', '+/-', '%'].contains(label);

        Color baseColor = const Color(0xFFF8F4EE); // Default number color
        Color textColor = const Color(0xFF3E3A32); // Dark brown-black

        if (isOperator) {
          baseColor = const Color(0xFFE8A44C); // Warm amber
          textColor = Colors.white;
        } else if (isTop) {
          baseColor = const Color(0xFFB8B0A4); // Warm gray
          textColor = const Color(0xFF3E3A32);
        }

        if (colors != null && index < colors.length) {
          baseColor = colors[index];
          // Infer text color for top row specific override if needed
          if (['÷', '×', '−', '+', '='].contains(label)) {
            textColor = Colors.white;
          }
        }

        return _SkeuomorphicButton(
          label: label,
          baseColor: baseColor,
          textColor: textColor,
          onPressed: () {},
        );
      }),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Double-wide 0 button
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.only(right: 14.0), // Gap roughly
            child: _SkeuomorphicButton(
              label: '0',
              baseColor: const Color(0xFFF8F4EE), // Off-white
              textColor: const Color(0xFF3E3A32),
              isPill: true,
              onPressed: () {},
            ),
          ),
        ),
        _SkeuomorphicButton(
          label: '.',
          baseColor: const Color(0xFFF8F4EE),
          textColor: const Color(0xFF3E3A32),
          onPressed: () {},
        ),
        const SizedBox(width: 14), // Gap
        _SkeuomorphicButton(
          label: '=',
          baseColor: const Color(0xFF4A6FA5), // Steel blue
          textColor: Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFDCD4C8), // Darker warm beige
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
          const BoxShadow(
            color: Colors.white, // Highlight bottom
            offset: Offset(0, 1),
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '한국어로 계산하기...',
              style: TextStyle(
                color: const Color(0xFF8A8578),
                fontSize: 16,
              ),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF6B8E5A), // Sage green
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFDCD4C8), // Slightly darker warm beige background
        border: Border(top: BorderSide(color: Color(0xFFC8C0B4), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.calculate, '계산기', true),
          _buildNavItem(Icons.smart_toy, 'AI 도우미', false),
          _buildNavItem(Icons.history, '기록', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? const Color(0xFF4A6FA5) : const Color(0xFF8A8578),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? const Color(0xFF4A6FA5) : const Color(0xFF8A8578),
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _SkeuomorphicButton extends StatelessWidget {
  final String label;
  final Color baseColor;
  final Color textColor;
  final bool isPill;
  final VoidCallback onPressed;

  const _SkeuomorphicButton({
    required this.label,
    required this.baseColor,
    required this.textColor,
    this.isPill = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPill ? double.infinity : 72,
      height: 72,
      decoration: BoxDecoration(
        color: baseColor,
        shape: isPill ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isPill ? BorderRadius.circular(36) : null,
        boxShadow: [
          // Bottom shadow (depth)
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(0, 4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
          // Top highlight (bevel effect)
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            offset: const Offset(0, -2),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withOpacity(0.9), // Lighter top-left
            baseColor, // Base
            baseColor.withOpacity(0.8), // Darker bottom-right
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: isPill
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(36))
              : const CircleBorder(),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
