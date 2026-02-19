# util-AIcalculator — CLAUDE.md

## 프로젝트 개요
40~60대 사용자를 위한 AI 계산기 앱.
Flutter (iOS + Android + **Web 우선**).

## 핵심 기술 스택
- Flutter 3.27.x + Dart ^3.6.2
- Riverpod 2.6.x (StateNotifier — 코드 생성 미사용)
- go_router 14.8.x (ShellRoute 3탭)
- Claude Haiku API (claude-haiku-4-5) — AI 기능 전담
- flutter_secure_storage / SharedPreferences — API 키 보관
- History: 메모리 기반 (Drift DB로 추후 교체 예정)

## 폴더 구조 요약
```
lib/
  core/          — 테마, 라우터, 유틸 (계산 엔진, 포맷터)
  data/          — 리포지토리 (HistoryRepository)
  domain/        — 서비스 (ClaudeService, SecureConfig)
  presentation/  — 화면 (calculator, ai_chat, history)
  providers/     — Riverpod 프로바이더 (theme, config)
```

## AI 기능 (claude_service.dart)
1. `parseNaturalLanguage(input)` — 자연어 → 계산 결과
2. `interpretContext(expr, result)` — 맥락 팁 (20자 이내 한국어)
3. `generateLabel(expr, result)` — 히스토리 레이블 (6자 이내)
4. `chat(messages)` — AI 채팅 탭 멀티턴 대화

## API 키 설정
- 앱 실행 후 계산기 탭 우상단 🔑 아이콘 → API 키 입력
- 웹: SharedPreferences, 모바일: Keychain/Keystore

## 개발 규칙
- **main 브랜치에 직접 commit/push 금지**
- 기능 브랜치: `feature/<이름>`, 버그 수정: `fix/<이름>`
- 커밋 전 `flutter analyze` 통과 필수
- API 키 하드코딩 절대 금지
- 웹 미지원 기능(OCR)은 `kIsWeb` 분기로 처리

## 실행
```bash
# 웹
flutter run -d chrome

# 빌드
flutter build web
```

## 향후 개선 예정
- [ ] Drift SQLite DB 교체 (현재 메모리 기반)
- [ ] web/index.html sql.js wasm 연동
- [ ] 영수증 OCR (모바일 전용, ML Kit + Claude)
- [ ] GitHub Actions CI/CD
