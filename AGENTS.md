# util-AIcalculator — AGENTS.md (개발 규칙 및 프로젝트 지침)

## 프로젝트 개요
40~60대 사용자를 위한 AI 계산기 앱.
Flutter (iOS + Android + **Web 우선**).

## 핵심 기술 스택
- Flutter 3.27.x + Dart ^3.6.2
- Riverpod 2.6.x (StateNotifier — 코드 생성 미사용)
- go_router 14.8.x (ShellRoute 3탭)
- Gemini API (gemini-3.1-flash-lite) — AI 기능 전담 (⚠️ 모델 변경 절대 금지)
- flutter_secure_storage / SharedPreferences — API 키 보관
- History & Storage: **Drift SQLite** (로컬 캐시) + **Supabase (supabase_flutter)** (원격 동기화)
- Hosting: **Vercel** (Flutter Web 자동 빌드 및 프리뷰)

## 폴더 구조 요약
```
lib/
  core/          — 테마, 라우터, 유틸 (계산 엔진, 포맷터, 설정)
  data/          — 리포지토리 (HistoryRepository), 로컬 DB, 원격 Supabase 서비스
  domain/        — 서비스 (GeminiService, SecureConfig)
  presentation/  — 화면 (calculator, ai_chat, history)
  providers/     — Riverpod 프로바이더 (theme, config)
```

## AI 기능 (gemini_service.dart)
1. `parseNaturalLanguage(input)` — 자연어 → 계산 결과
2. `chat(messages)` — AI 채팅 탭 멀티턴 대화

## 환경변수 (.env) 설정
- `.env` 파일에 아래 환경변수 저장 (git 제외):
  - `GEMINI_API_KEY=...`
  - `SUPABASE_URL=...` (선택: 원격 동기화 활성화 시)
  - `SUPABASE_ANON_KEY=...` (선택: 원격 동기화 활성화 시)
- 앱 실행 후 계산기 탭 우상단 🔑 아이콘 → UI에서 직접 입력도 가능
- 우선순위: UI 입력 키 > `.env` 키

## 개발 규칙
- **main 브랜치에 직접 commit/push 금지**
- 기능 브랜치: `feature/<이름>`, 버그 수정: `fix/<이름>`
- 커밋 전 `flutter analyze` 통과 필수
- API 키 하드코딩 절대 금지
- 웹 미지원 기능(OCR)은 `kIsWeb` 분기로 처리
- **큰 작업 완료 시 `SESSION_LOG.md` 갱신 필수** (핸드오프 및 타 환경 작업 인수인계용)
- **"작업완료해줘 / 수고했어" 요청 시 표준 종료 프로세스 실행**:
  1. 남은 변경사항 커밋 및 GitHub 푸시
  2. GitHub PR 생성 및 머지 상태 확인
  3. `SESSION_LOG.md`에 최종 결과 기록
  4. 로컬 `main` 원본 폴더 동기화 (`git pull`)

### 브랜치 전략
- **1 브랜치 = 1 기능** (독립 단위로 분리, 여러 기능을 한 브랜치에 섞지 않음)
- 브랜치 수명은 짧게 유지: 만들고 → 작업 → PR → 머지 → 삭제
- 새 세션에서 새 작업 시작 시, 반드시 main에서 새 브랜치 생성
- 하나의 PR에 관련 없는 변경을 묶지 않음 (리뷰·롤백 용이하게)
- 머지 완료된 feature 브랜치는 삭제하여 브랜치 목록 정리

## 실행
```bash
# 웹 개발 서버 (API 키 자동 주입 — 반드시 이 명령 사용)
bash run_dev.sh

# 직접 실행 시 API 키가 초기화되므로 금지
# flutter run -d chrome  ← 사용 금지

# 빌드
flutter build web --dart-define-from-file=.env
```

> **주의**: `flutter run -d chrome`을 직접 실행하면 `.env`의 API 키가 주입되지 않아
> 매번 UI에서 API 키를 다시 입력해야 합니다. 항상 `bash run_dev.sh` 사용.

## 향후 개선 예정
- [ ] 영수증 OCR (모바일 전용, ML Kit + Gemini)
- [ ] GitHub Actions CI/CD
