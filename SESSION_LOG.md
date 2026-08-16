# SESSION LOG & HANDOFF

이 문서는 프로젝트의 작업 이력과 상태를 기록하는 핸드오프 문서입니다. 다른 환경이나 세션에서 작업을 이어받을 때 이 문서를 가장 먼저 참고합니다.

---

## 📌 1. 현재 프로젝트 상태 및 인프라 요약

- **앱 종류**: 40~60대 타깃 AI 계산기 (Flutter Web 우선, iOS/Android 지원)
- **라이브 URL**: [https://migratetoverceldb.vercel.app](https://migratetoverceldb.vercel.app)
- **호스팅**: **Vercel** (`birddogmary24-bits-projects/migrate_to_vercel_db`)
- **원격 DB / BaaS**: **Supabase** (`ai-calculator`, 리전: 서울 `ap-northeast-2`)
- **로컬 캐시 DB**: Drift SQLite (Wasm / IndexedDB)

### 연결된 인프라 리소스
| 서비스 | 리소스명 | ID / Ref | 대시보드 링크 |
|:---|:---|:---|:---|
| **Vercel** | `migrate_to_vercel_db` | `prj_...` | [Vercel Project Dashboard](https://vercel.com/birddogmary24-bits-projects/migrate_to_vercel_db) |
| **Supabase** | `ai-calculator` | `xubpbdfiaolwrjckfltp` | [Supabase Dashboard](https://supabase.com/dashboard/project/xubpbdfiaolwrjckfltp) |
| **Supabase Org** | `waynepark-personal` | `jtxjearocpjckizjkyxd` | - |
| **GitHub PR** | `feat: migrate hosting to Vercel and remote database to Supabase` | `#2` | [GitHub PR #2](https://github.com/birddogmary24-bit/util-AIcalculator/pull/2) |

### 원격 DB 스키마 (Supabase)
- **`public.calculations`**:
  - `id` (uuid, PK)
  - `user_id` (text, default 'anonymous')
  - `expression` (text)
  - `result` (text)
  - `source` (text, default 'keypad')
  - `created_at` (timestamptz)
  - RLS: 활성화 (`Allow all operations` 정책 적용)

---

## 🔄 2. Git 표준 작업 워크플로우 (규칙)

모든 작업은 아래 **5단계 표준 루틴**으로 진행합니다:

```
[1. Commit] (로컬 저장) ➡️ [2. Push] (GitHub 브랜치 생성/업로드) ➡️ [3. PR] (풀 리퀘스트 생성) 
➡️ [4. Merge] (GitHub 웹에서 승인/합치기) ➡️ [5. Pull] (로컬 main 최신화)
```

1. 새 작업 시 **독립 브랜치**에서 시작
2. 작업 완료 및 `flutter analyze` 통과 시 **Commit & GitHub으로 Push**
3. **GitHub PR 자동 생성** 후 링크 전달
4. 사용자가 GitHub 웹에서 **[Merge]** 승인
5. 큰 단위 작업 완료 시 **`SESSION_LOG.md` 갱신 필수**

---

## 🔑 3. 필수 환경변수 목록

로컬(`.env`) 및 Vercel(Production, Preview)에 주입되는 변수:
- `GEMINI_API_KEY`: Google AI Studio Gemini API Key
- `SUPABASE_URL`: `https://xubpbdfiaolwrjckfltp.supabase.co`
- `SUPABASE_ANON_KEY`: Supabase anon public key

---

## 🛠 4. 최근 작업 이력

### [2026-08-17] 뒤로가기(백스페이스) 버튼 추가 및 LCD 레이아웃 개편
- **뒤로가기(백스페이스) 계산 엔진 및 상태 연동**:
  - `CalculatorEngine`: `backspace()` 메소드 구현 (한 글자 지우기, 1글자 남았을 때 0으로 리셋, 연산자 직후 누를 시 연산자 취소 및 이전 숫자 복원 등)
  - `CalculatorNotifier`: `backspace()` 액션 추가
  - `test/calculator_backspace_test.dart`: 단위 테스트 작성 및 통과 (6개 케이스)
- **UI 및 아이콘 벡터 렌더링 (`CustomPainter`)**:
  - Flutter Web Icon 트리셰이킹 누락 문제를 해결하기 위해 `_ChevronLeftPainter`로 굵은 흰색 `<` 꺾쇠 화살표 벡터 드로잉 구현
  - 마이크 버튼과 동일한 블루 그라데이션 원형 버튼 및 햅틱/터치 스케일 애니메이션 적용
- **LCD 디스플레이 패널 레이아웃 전면 개편**:
  - 메인 입력/결과 숫자를 독립된 한 줄 전체 행으로 분리하여 자리수가 늘어나도 폰트 크기 요동 없이 안정적인 크기(46pt 고정) 유지
  - 히스토리 영역을 컴팩트한 1줄 포맷(`120 + 350 = 470`)으로 최적화
  - 하단 컨트롤 바 정돈: 좌측 `[마이크] [뒤로가기]`, 우측 `[AI 뱃지] [복사]`
- **Vercel 프로덕션 자동 배포 및 PR 머지 완료**

### [2026-08-16] Vercel + Supabase 마이그레이션 및 프로덕션 배포
- **Firebase ➡️ Vercel 전환**:
  - `firebase.json`, `.firebaserc` 제거
  - `vercel.json` 및 `vercel-build.sh` 생성 (Flutter SDK 자동 설치 & build web 실행)
- **Supabase DB 구축**:
  - CLI로 Supabase 조직/프로젝트 생성 및 `calculations` 테이블 생성 + RLS 세팅
  - `supabase_flutter` 패키지 추가 및 `SupabaseService`, `SupabaseConfig`, `HistoryRepository` 동기화 로직 구현
  - Supabase 키가 없거나 오프라인일 때도 로컬 Drift DB로 정상 작동하는 fallback 구조 적용
- **빌드 및 호환성 최적화**:
  - `build.yaml` 추가: `build_runner`의 Drift 스캔 범위를 `app_database.dart` 1개로 제한하여 생성 시간 단축 (수십 분 멈춤 ➡️ **1.4초**)
  - Dart 3.13 / Web 컴파일러 호환 이슈가 있던 `google_fonts` 제거하고 로컬 Pretendard 폰트 및 모노스페이스 스타일로 교체
- **배포 및 환경변수 주입 완료**:
  - Vercel CLI로 환경변수 3종(`GEMINI_API_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`) 등록 및 프로덕션 배포 완료
- **GitHub PR 생성**:
  - `migrate_to_vercel_db` 브랜치를 GitHub에 푸시하고 [PR #2](https://github.com/birddogmary24-bit/util-AIcalculator/pull/2) 생성 완료

---

## 🚀 5. 새 환경 / 다른 컴퓨터에서 작업 이어받기

1. **저장소 클론 후 의존성 설치**:
   ```bash
   flutter pub get
   ```
2. **코드 생성 (필요 시)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
3. **환경변수 설정**:
   - `.env.example`을 복사하여 `.env` 생성 후 실제 키 입력
4. **로컬 실행**:
   ```bash
   bash run_dev.sh
   # 브라우저에서 http://localhost:8080 접속
   ```
5. **Vercel 수동 배포 (CLI)**:
   ```bash
   npx -y vercel --prod
   ```

---

## 📋 6. 향후 작업 백로그
- [ ] Supabase 계산 기록 복원/불러오기 UI 연동 (히스토리 화면에서 원격 백업 조회)
- [ ] 영수증 OCR 기능 (모바일 전용)
- [ ] 다크 모드 및 접근성 개선
