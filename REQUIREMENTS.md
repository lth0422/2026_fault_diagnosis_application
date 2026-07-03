# 요구사항 명세 (REQUIREMENTS)

## 1. 개요

본 문서는 Flutter 기반 결함 진단 애플리케이션의 요구사항을 정의한다.
기존 Kotlin Android 앱은 참조 구현이며, 신규 앱은 Flutter/Dart로 재작성한다.

## 2. 대상 플랫폼

- Android
- iOS
- 단일 Flutter/Dart 코드베이스로 두 플랫폼을 지원한다.

## 3. 기능 요구사항 (Functional Requirements)

### 3.1 화면 흐름
- FR-1. 앱은 다음 순서의 화면 흐름을 제공한다:
  StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage →
  MarkerColorPage → HsvSettingPage → MarkerCenterPage →
  DisplacementPage → FaultDiagnosisPage
- FR-2. 각 화면은 다음 화면으로 이동할 수 있어야 하며, 이전 화면으로 돌아갈 수 있어야 한다.

### 3.2 데이터 구조
- FR-3. 진단 과정의 상태는 `DiagnosisSession` 으로 관리한다.
- FR-4. 다음 기본 데이터 모델을 정의한다:
  `VideoInfo`, `RoiInfo`, `HsvRange`, `MarkerInfo`, `DisplacementResult`, `DiagnosisResult`.

### 3.3 1차 마일스톤 기능 범위
- FR-5. 1차 마일스톤에서는 페이지 네비게이션만 구현한다.
- FR-6. DisplacementPage, FaultDiagnosisPage 는 **mock 데이터**로만 결과를 표시한다.
- FR-7. 실제 영상 처리, 마커 검출, 변위 계산, 모델 추론은 구현하지 않는다.

### 3.4 진단 모델 (향후)
- FR-8. 모델 입력은 **DisplacementZ** 시계열을 사용한다.
- FR-9. 모델 입력 길이는 **2048** 이다.
- FR-10. 모델 입력 형상은 **[1, 1, 2048]** 이다.
- FR-11. 출력 클래스 순서는 **B, H, IR, OR** 이다.

## 4. 비기능 요구사항 (Non-Functional Requirements)

- NFR-1. 코드베이스는 Flutter/Dart로 작성하며 Android/iOS를 동시에 지원한다.
- NFR-2. 초기 개발은 UI 흐름과 데이터 구조의 명확성을 우선한다.
- NFR-3. 폴더 구조와 문서는 유지보수 및 확장이 쉽도록 구성한다.
- NFR-4. 상태 관리는 `provider` 패키지를 사용한다(향후 코드 단계에서 적용).

## 5. 제약사항 (Constraints)

- C-1. 기존 Kotlin Android 앱은 **참조 구현**이며 수정하지 않는다.
- C-2. 1차 마일스톤에서는 다음을 **구현하지 않는다**:
  OpenCV, Core ML, ONNX, PyTorch, 네이티브 MethodChannel, 실제 영상 처리.
- C-3. 모든 작업은 저장소 `2026_fault_diagnosis_application` 내부에서만 수행한다.

## 6. 용어

- **ROI (Region Of Interest)**: 영상 내 관심 영역.
- **HSV**: 색상(Hue)·채도(Saturation)·명도(Value) 색공간.
- **Marker**: 변위 추적 대상이 되는 색상 마커.
- **DisplacementZ**: 결함 진단 모델의 입력이 되는 변위 시계열 데이터.
- **클래스 (B/H/IR/OR)**: 결함 유형 분류 레이블.
