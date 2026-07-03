# AGENTS.md — Codex Agent 작업 지침

이 파일은 ChatGPT Codex Agent가 이 저장소에서 작업할 때 따라야 할 규칙을 정의한다.

## 프로젝트 개요

기존 **Kotlin Android 결함 진단 앱**을 **Flutter/Dart** 기반 Android/iOS 크로스 플랫폼 앱으로 전환하는 프로젝트.

- 신규 앱 위치: `flutter_app/`
- 레거시 앱 위치: `legacy_android/` (읽기 전용 참조, 절대 수정 금지)
- 상태 관리: `provider` 패키지 + `DiagnosisSession` (ChangeNotifier)

## 절대 규칙

1. `legacy_android/` 폴더 내 파일은 절대 수정하지 않는다 (읽기 전용 참조).
2. 모든 코드 작업은 `flutter_app/` 안에서만 수행한다.
3. 저장소 외부 파일은 건드리지 않는다.

## 1차 마일스톤 범위

**구현 완료 (건드리지 말 것)**
- 9개 페이지 골격 + 네비게이션 흐름
- DiagnosisSession, VideoInfo, RoiInfo, HsvRange, MarkerInfo, DisplacementResult, DiagnosisResult 모델
- DisplacementService / DiagnosisService (mock 데이터)
- NativeDiagnosisChannel (stub)
- StepHeader, PrimaryButton, RoiPainter, ProbabilityBar 위젯

**미구현 (현재 Out of Scope)**
- 실제 영상 파일 선택 (file_picker)
- OpenCV ROI 처리
- HSV 마커 추적
- 변위 계산
- PyTorch Mobile Lite 모델 추론
- 네이티브 MethodChannel

## 앱 화면 흐름

```
StartPage (/)
  → VideoSelectPage (/video-select)
    → VideoInfoPage (/video-info)
      → RoiSettingPage (/roi)
        → MarkerColorPage (/marker-color)
          → HsvSettingPage (/hsv)
            → MarkerCenterPage (/marker-center)
              → DisplacementPage (/displacement)
                → FaultDiagnosisPage (/diagnosis)
```

## 진단 모델 사양

| 항목 | 값 |
|------|-----|
| 입력 | DisplacementZ (변위 시계열) |
| 입력 형상 | [1, 1, 2048] |
| 클래스 순서 | B, H, IR, OR |
| 후처리 | softmax → 최대 확률 클래스 |
| 결과 색상 | H = 파랑(#1976D2), 그 외 = 빨강(#D32F2F) |
| 레거시 엔진 | PyTorch Mobile Lite (Fwdcnn7.ptl) |

## 주요 파일 위치

| 역할 | 경로 |
|------|------|
| 라우트 등록 | `flutter_app/lib/app.dart` |
| 전역 상태 | `flutter_app/lib/models/diagnosis_session.dart` |
| 페이지 | `flutter_app/lib/pages/` |
| 모델 | `flutter_app/lib/models/` |
| 서비스 | `flutter_app/lib/services/` |
| 위젯 | `flutter_app/lib/widgets/` |
| 네이티브 채널 stub | `flutter_app/lib/platform/native_diagnosis_channel.dart` |
| 레거시 참조 | `legacy_android/X-twice-app_integration/X-twice-app_integration/app/src/main/java/com/example/useopencvwithcmakeandkotlin/` |

## 코드 컨벤션

- Dart/Flutter 표준 스타일 준수 (`flutter analyze` 경고 없어야 함)
- 페이지 이동: `Navigator.pushNamed(context, XxxPage.routeName)`
- 상태 읽기: `context.read<DiagnosisSession>()`
- 상태 구독: `context.watch<DiagnosisSession>()`
- 위젯은 `const` 생성자 우선 사용

## 레거시 참조 방법

새 기능 구현 전 반드시 레거시 Activity 를 먼저 읽어 UI 흐름/로직을 파악한다.

| Flutter Page | 대응 legacy Activity |
|---|---|
| StartPage | StartActivity.kt |
| VideoSelectPage | MainActivity.kt |
| VideoInfoPage | VideoSizeActivity.kt |
| RoiSettingPage | ROIActivity.kt |
| MarkerColorPage | MarkerColorActivity.kt |
| HsvSettingPage | HSVActivity.kt |
| MarkerCenterPage | MarkerCenterActivity.kt |
| DisplacementPage | DisplacementActivity.kt |
| FaultDiagnosisPage | FaultDiagnosisActivity.kt |
