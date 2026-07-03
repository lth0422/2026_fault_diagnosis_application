# 개발 로그 (Development Log)

프로젝트 진행 사항을 시간순으로 기록한다. 최신 항목이 위쪽에 오도록 작성한다.

---

## 2026-07-03 — 하단 액션 버튼 시스템 내비게이션 여백 보정

**작업 내용**
- Galaxy 기기에서 하단 "다음/확인/완료" 버튼이 시스템 홈/내비게이션 영역에 가까워 불편한 문제 수정.
- 하단 액션으로 쓰이는 `PrimaryButton`에만 `SafeArea` 기반 하단 여백 옵션을 적용.
- `MarkerCenterPage`의 하단 버튼 행은 행 전체에 같은 하단 여백을 적용해 버튼 높이를 맞춤.
- 기본 카운터 테스트를 현재 `FaultDiagnosisApp` 시작 화면 smoke test로 교체.

**생성/수정 파일**
- `flutter_app/lib/widgets/primary_button.dart`
- `flutter_app/lib/pages/start_page.dart`
- `flutter_app/lib/pages/video_select_page.dart`
- `flutter_app/lib/pages/video_info_page.dart`
- `flutter_app/lib/pages/roi_setting_page.dart`
- `flutter_app/lib/pages/hsv_setting_page.dart`
- `flutter_app/lib/pages/marker_center_page.dart`
- `flutter_app/lib/pages/displacement_page.dart`
- `flutter_app/lib/pages/fault_diagnosis_page.dart`
- `flutter_app/test/widget_test.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

## 2026-07-03 — Android Flutter 빌드 Gradle DSL 정리

**작업 내용**
- 실제 Android 기기(`SM S911N`)에서 `flutter run` 시 Gradle 빌드가 실패하는 원인 확인.
- `android/` 폴더에 Groovy DSL(`*.gradle`)과 Kotlin DSL(`*.gradle.kts`) 설정이 함께 있어
  오래된 Groovy 설정이 우선 적용되는 문제를 정리.
- 이후 AGP 9/new DSL 조합에서 Flutter Gradle plugin NPE가 발생해 Android 빌드 설정을
  안정 조합(AGP 8.7.3, Gradle 8.10.2, Kotlin 2.0.21)으로 조정.

**생성/수정/삭제 파일**
- 삭제: `flutter_app/android/settings.gradle`
- 삭제: `flutter_app/android/build.gradle`
- 삭제: `flutter_app/android/app/build.gradle`
- 수정: `flutter_app/android/gradle.properties` — AGP 9 new DSL/내장 Kotlin 플래그 비활성화
- 수정: `flutter_app/android/settings.gradle.kts` — Android/Kotlin Gradle plugin 버전 조정
- 수정: `flutter_app/android/gradle/wrapper/gradle-wrapper.properties` — Gradle wrapper 버전 조정
- 수정: `flutter_app/android/app/build.gradle.kts` — Kotlin Android plugin 명시
- 수정: `docs/development_log.md` — 본 로그 항목 추가

**결정 사항**
- Flutter가 생성한 Kotlin DSL 설정(`settings.gradle.kts`, `build.gradle.kts`,
  `app/build.gradle.kts`)을 Android 빌드 기준으로 사용한다.
- 현재 Flutter 실행 검증은 AGP 9/new DSL 대신 AGP 8.x 안정 조합으로 진행한다.

**실행 확인**
- `flutter clean`, `flutter pub get` 성공.
- `flutter run -d R3CWB0JYD4A`로 `app-debug.apk` 빌드 및 `SM S911N` 설치 성공.
- 실행 직후 Flutter 디버그 세션은 `Lost connection to device`로 종료되었으나,
  빌드/설치 단계는 정상 완료됨.

## 2026-07-03 — Flutter 전환 현황 점검 및 작업 노트 추가

**작업 내용**
- 저장소 구조, `legacy_android/`, `flutter_app/`, `docs/` 구성을 점검.
- Flutter 앱이 Android/iOS 전환용 신규 앱이며, legacy Android 앱은 참조 구현임을 재확인.
- 현재 1차 마일스톤 범위와 향후 네이티브/모델 통합 범위를 구분하는 작업 노트 추가.

**생성/수정 파일**
- `docs/flutter_transition_notes.md` — Flutter 전환 작업 기준, 현재 구조, 주의사항, 다음 체크포인트
- `docs/development_log.md` — 본 로그 항목 추가

**확인 사항**
- `flutter_app/lib/`에는 9단계 페이지, 기본 모델, provider 기반 `DiagnosisSession`,
  mock 서비스 구조가 이미 존재한다.
- `platform/native_*_channel.dart`는 향후 마일스톤용 스텁이며, 1차 마일스톤에서는
  MethodChannel을 연결하지 않는다.
- `flutter_app/test/widget_test.dart`는 기본 카운터 앱 테스트 상태로 보여,
  현재 앱 기준 smoke test로 교체가 필요하다.

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
