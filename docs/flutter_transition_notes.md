# Flutter 전환 작업 노트

이 문서는 기존 Kotlin Android 앱을 Flutter/Dart 기반 Android/iOS 앱으로 전환할 때
작업자가 빠르게 맥락을 잡기 위한 실행 노트이다.

## 현재 목표

- 최종 목표: Flutter 단일 코드베이스로 Android/iOS 앱 제공.
- 현재 실험 대상: Flutter Android 앱 실행 및 UI 흐름 검증.
- 현재 마일스톤: 실제 영상 처리나 모델 추론이 아니라 UI 흐름, 데이터 모델,
  mock 데이터 기반 화면 연결을 먼저 안정화한다.

## 저장소 구조

```text
.
├─ legacy_android/   기존 Kotlin Android 앱. 참조용이며 수정 금지.
├─ flutter_app/      신규 Flutter/Dart 앱.
├─ docs/             전환 문서, 모델 사양, 작업 로그.
├─ AGENTS.md         저장소 작업 규칙.
├─ PROJECT_PLAN.md   프로젝트 계획.
├─ REQUIREMENTS.md   요구사항.
└─ README.md         프로젝트 개요.
```

## legacy_android 사용 원칙

- `legacy_android/`는 참조 구현(reference implementation)으로만 사용한다.
- 화면 흐름, UI 구성, 데이터 전달 방식, 모델 입출력 규칙을 파악할 때만 읽는다.
- legacy 코드를 직접 수정하거나 Flutter 앱에 그대로 복사하지 않는다.
- OpenCV, PyTorch Mobile, 네이티브 처리 로직은 이후 마일스톤에서 별도로 설계한다.

## Flutter 앱 현황

`flutter_app/lib/`는 다음 기준으로 구성되어 있다.

```text
lib/
├─ main.dart      앱 진입점
├─ app.dart       MaterialApp, provider, named routes
├─ models/        DiagnosisSession 및 기본 데이터 모델
├─ pages/         9단계 화면
├─ services/      mock 서비스 및 미래 구현용 스텁
├─ platform/      네이티브 채널 래퍼 스텁
└─ widgets/       공용 UI 위젯
```

현재 화면 흐름은 다음 순서를 따른다.

```text
StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage →
MarkerColorPage → HsvSettingPage → MarkerCenterPage →
DisplacementPage → FaultDiagnosisPage
```

## 1차 마일스톤에서 허용되는 작업

- 페이지 플레이스홀더와 named route 네비게이션 정리.
- `DiagnosisSession` 중심의 상태 전달 정리.
- 다음 데이터 모델 보강:
  `DiagnosisSession`, `VideoInfo`, `RoiInfo`, `HsvRange`, `MarkerInfo`,
  `DisplacementResult`, `DiagnosisResult`.
- `DisplacementPage`, `FaultDiagnosisPage`의 mock 데이터 표시 개선.
- Flutter Android 실행을 위한 기본 생성 파일 점검.
- 문서와 개발 로그 갱신.

## 1차 마일스톤에서 피해야 할 작업

- OpenCV 구현.
- Core ML, ONNX, PyTorch, PyTorch Mobile 통합.
- 커스텀 MethodChannel 구현.
- 실제 영상 처리, 마커 추적, 변위 계산, 모델 추론.
- legacy Android 앱 수정.

## 주의할 점

- `platform/native_*_channel.dart` 파일은 향후 마일스톤용 스텁이다.
  현재 단계에서는 MethodChannel을 연결하지 않는다.
- `DisplacementService.mockResult()`는 모델 입력 길이 2048에 맞춘 mock
  `DisplacementZ` 데이터를 만든다.
- 진단 클래스 순서는 항상 `B, H, IR, OR`를 유지한다.
- 모델 입력 사양은 `docs/model_io_spec.md`를 기준으로 한다.

## 다음 체크포인트

1. `flutter_app/test/widget_test.dart`가 기본 카운터 앱 테스트로 남아 있는지 확인하고,
   현재 `FaultDiagnosisApp` 기준의 smoke test로 교체한다.
2. Android에서 `flutter create .`, `flutter pub get`, `flutter analyze`,
   `flutter run` 흐름이 가능한지 확인한다.
3. `PROJECT_PLAN.md`의 1차 마일스톤 체크박스를 실제 구현 상태에 맞게 갱신한다.
4. `DisplacementPage`, `FaultDiagnosisPage`가 mock 데이터만 사용한다는 경계를 유지한다.
