# 개발 로그 (Development Log)

프로젝트 진행 사항을 시간순으로 기록한다. 최신 항목이 위쪽에 오도록 작성한다.

---

## 2026-07-02 — 프로젝트 문서화 초기 작성

**작업 내용**
- 프로젝트 초기 문서 세트 작성.
- 기존 Kotlin Android 앱 → Flutter/Dart 전환 방향 및 범위 정의.

**생성/수정 파일**
- `README.md` (갱신) — 프로젝트 개요, 화면 흐름, 문서 색인
- `PROJECT_PLAN.md` — 목표, 마일스톤, 화면 흐름, 범위
- `REQUIREMENTS.md` — 기능/비기능 요구사항, 제약사항
- `CLAUDE.md` — 저장소 작업 규칙
- `docs/android_activity_mapping.md` — Activity → Page 매핑
- `docs/model_io_spec.md` — 모델 입출력 사양
- `docs/development_log.md` — 개발 로그 (본 파일)

**결정 사항**
- 대상 플랫폼: Android, iOS (Flutter/Dart 단일 코드베이스).
- 1차 마일스톤은 UI 흐름과 데이터 구조 정의에 집중.
- 상태 관리는 `provider` 패키지 사용 예정.
- 진단 모델 사양 확정: 입력 DisplacementZ, 길이 2048, 형상 [1, 1, 2048],
  클래스 순서 B, H, IR, OR.

**범위 제외 (재확인)**
- OpenCV, Core ML, ONNX, PyTorch, 네이티브 MethodChannel, 실제 영상 처리.

**다음 예정 작업**
- Flutter 프로젝트 골격 및 `lib/` 폴더 구조 생성.
- 9개 페이지 플레이스홀더 및 네비게이션 구현.
- 기본 데이터 모델 정의 및 mock 데이터 연결.
