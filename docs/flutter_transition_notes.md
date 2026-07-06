# Flutter 전환 작업 노트

이 문서는 기존 Kotlin Android 앱을 Flutter/Dart 기반 Android/iOS 앱으로 전환할 때
작업자가 빠르게 맥락을 잡기 위한 실행 노트이다.

> 업데이트: 이 문서는 초기 전환 단계의 작업 노트이다. 현재 Flutter Android 앱은
> 실제 로컬 영상 선택, OpenCV HSV/변위 계산, CSV 저장/내보내기, PyTorch Lite
> 모델 추론, 진행률 표시, HSV 디버그 화면까지 구현되어 있다. 최신 구현 현황은
> `docs/flutter_android_migration_report.md`와 `docs/development_log.md`를 기준으로 본다.

## 현재 목표

- 최종 목표: Flutter 단일 코드베이스로 Android/iOS 앱 제공.
- 현재 실험 대상: Flutter Android 앱에서 실제 영상 처리/모델 추론 검증 후 iOS 실험으로 확장.
- 현재 Android 상태: 로컬 영상 선택, ROI/HSV 설정, OpenCV 변위 계산, CSV 저장/공유,
  PyTorch Lite 모델 추론까지 연결.

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
├─ services/      영상 선택, HSV 미리보기, 변위 계산, 모델 추론 서비스
├─ platform/      네이티브 채널 래퍼 스텁
└─ widgets/       공용 UI 위젯
```

현재 화면 흐름은 다음 순서를 따른다.

```text
StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage →
MarkerColorPage → HsvSettingPage → MarkerCenterPage →
DisplacementPage → FaultDiagnosisPage
```

## 초기 1차 마일스톤에서 허용되었던 작업

- 페이지 플레이스홀더와 named route 네비게이션 정리.
- `DiagnosisSession` 중심의 상태 전달 정리.
- 다음 데이터 모델 보강:
  `DiagnosisSession`, `VideoInfo`, `RoiInfo`, `HsvRange`, `MarkerInfo`,
  `DisplacementResult`, `DiagnosisResult`.
- `DisplacementPage`, `FaultDiagnosisPage`의 mock 데이터 표시 개선.
- Flutter Android 실행을 위한 기본 생성 파일 점검.
- 문서와 개발 로그 갱신.

## 초기 1차 마일스톤에서 피했던 작업

- OpenCV 구현.
- Core ML, ONNX, PyTorch, PyTorch Mobile 통합.
- 커스텀 MethodChannel 구현.
- 실제 영상 처리, 마커 추적, 변위 계산, 모델 추론.
- legacy Android 앱 수정.

## 주의할 점

- `platform/native_*_channel.dart` 파일은 향후 마일스톤용 스텁이다.
  현재 단계에서는 MethodChannel을 연결하지 않는다.
- Android에서는 실제 OpenCV/PyTorch Lite 네이티브 채널을 사용한다.
- 비 Android 플랫폼은 iOS 구현 전까지 일부 fallback/mock 경로가 남아 있을 수 있다.
- 진단 클래스 순서는 항상 `B, H, IR, OR`를 유지한다.
- 모델 입력 사양은 `docs/model_io_spec.md`를 기준으로 한다.

## 다음 체크포인트

1. Android 테스트 영상 세트별로 파일명 라벨과 모델 예측 결과를 기록한다.
2. HSV 검출 비율, 변위 Z 표준편차, logits를 함께 기록해 모델 입력 품질을 검증한다.
3. iOS 실험 전 `docs/ios_porting_preparation.md`의 MethodChannel 계약을 기준으로 구현 범위를 나눈다.
4. iOS에서는 영상 선택 파일을 앱 sandbox로 복사하는 방식부터 검증한다.
