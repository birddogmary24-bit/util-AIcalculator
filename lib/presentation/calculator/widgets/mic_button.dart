import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../core/constants/region.dart';
import '../../../core/theme/colors.dart';

/// 공용 마이크 버튼 위젯.
/// - speechAvailable: STT 권한 있음
/// - isListening: 현재 청취 중
/// - onResult: 인식된 텍스트 반환
/// - size: 버튼 크기 (기본 40)
class MicButton extends StatefulWidget {
  final bool speechAvailable;
  final bool isListening;
  final double size;
  final RegionMode region;
  final void Function(String text) onResult;
  final VoidCallback? onStart;
  final VoidCallback? onStop;

  const MicButton({
    super.key,
    required this.speechAvailable,
    required this.isListening,
    required this.region,
    required this.onResult,
    this.onStart,
    this.onStop,
    this.size = 40,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> {
  /// 권한 없음 → 팝업 표시
  void _showPermissionDialog(BuildContext context) {
    final isKr = widget.region == RegionMode.kr;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isKr ? '마이크 권한 필요' : 'Microphone Permission Required'),
        content: Text(
          isKr
              ? '음성 입력을 사용하려면 마이크 권한이 필요합니다.\n\n설정에서 권한을 허용해주세요:\n설정 → 앱 → AI Calculator → 권한 → 마이크'
              : 'Microphone access is required for voice input.\n\nPlease allow it in:\nSettings → Apps → AI Calculator → Permissions → Microphone',
          style: const TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isKr ? '닫기' : 'Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.speechAvailable;

    return GestureDetector(
      onTap: () {
        if (!active) {
          _showPermissionDialog(context);
          return;
        }
        if (widget.isListening) {
          widget.onStop?.call();
        } else {
          widget.onStart?.call();
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: widget.isListening
              ? null
              : (active
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
                  : null),
          color: widget.isListening
              ? AppColors.error
              : (!active ? AppColors.expressionText.withAlpha(40) : null),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: active ? Colors.white : Colors.white38,
          size: widget.size * 0.5,
        ),
      ),
    );
  }
}

/// STT 초기화 + 음성 인식 로직을 포함한 Stateful 래퍼.
/// AiChatScreen처럼 자체 STT 인스턴스가 필요한 곳에서 사용.
class MicButtonController extends StatefulWidget {
  final RegionMode region;
  final double size;
  final void Function(String text) onResult;

  const MicButtonController({
    super.key,
    required this.region,
    required this.onResult,
    this.size = 40,
  });

  @override
  State<MicButtonController> createState() => _MicButtonControllerState();
}

class _MicButtonControllerState extends State<MicButtonController> {
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

  Future<void> _startListening() async {
    if (!_speechAvailable || _isListening) return;
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        final text = result.recognizedWords;
        if (result.finalResult && text.isNotEmpty) {
          setState(() => _isListening = false);
          widget.onResult(text);
        }
      },
      localeId: widget.region == RegionMode.kr ? 'ko_KR' : 'en_US',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(cancelOnError: true),
    );
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MicButton(
      speechAvailable: _speechAvailable,
      isListening: _isListening,
      region: widget.region,
      size: widget.size,
      onResult: widget.onResult,
      onStart: _startListening,
      onStop: _stopListening,
    );
  }
}
