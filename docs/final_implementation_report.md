# Flutter 결함 진단 앱 최종 구현 보고서

이 문서는 기존 Kotlin Android 결함 진단 앱을 Flutter 기반 Android/iOS 앱으로 이전한 최종 구현 상태를 보고용으로 정리한 문서이다.

## 1. 프로젝트 목표

기존 앱은 OpenCV로 영상 ROI 안의 마커를 추적하고, 변위 시계열을 CSV로 저장한 뒤, PyTorch Mobile Lite 모델로 결함을 진단하는 Android 앱이었다.

이번 작업의 목표는 다음과 같다.

- 기존 Android 앱의 핵심 진단 흐름을 Flutter 앱으로 이전한다.
- Android에서 실제 영상 처리, CSV 저장/공유, 내장 모델 추론까지 검증한다.
- 같은 Flutter `lib/` UI와 상태 구조를 유지하면서 iOS 실기기에서도 진단 흐름을 실행한다.

## 2. 최종 앱 흐름

Flutter 앱은 다음 9단계 화면 흐름으로 구성된다.

```text
StartPage
  -> VideoSelectPage
    -> VideoInfoPage
      -> RoiSettingPage
        -> MarkerColorPage
          -> HsvSettingPage
            -> MarkerCenterPage
              -> DisplacementPage
                -> FaultDiagnosisPage
```

각 화면은 `DiagnosisSession`에 선택 영상, ROI, HSV 범위, 마커 중심, 변위 결과, 진단 결과를 누적 저장한다.

## 3. 구현 완료 범위

### 3.1 공통 Flutter 영역

- `provider` 기반 전역 상태 관리 구조 구현.
- Android/iOS 공통 화면 흐름 구현.
- 영상 정보 입력, 해상도/FPS 프리셋, ROI 지정 UI 구현.
- 마커 색상 선택 및 HSV slider 조정 UI 구현.
- HSV 검출 품질 확인용 원본/검출 이미지 전환 화면 구현.
- 마커 중심 지정 및 추적 박스 크기 조정 UI 구현.
- 변위 계산 진행률 표시 UI 구현.
- CSV 저장 위치 및 내보내기 버튼 표시.
- 모델 진단 결과와 클래스별 확률 표시.
- 하단 버튼과 겹치던 `SnackBar`를 제거하고 상단 `MaterialBanner` 알림으로 교체.

### 3.2 Android 구현

Android에서는 실제 진단 파이프라인이 네이티브 채널로 연결되었다.

| 기능 | 구현 상태 |
|---|---|
| 영상 선택 | 로컬 파일 선택기 기반 선택 및 앱 캐시 복사 |
| 첫 프레임/ROI 추출 | Android 네이티브 + OpenCV |
| HSV 미리보기 | OpenCV `inRange` 기반 실시간 검출 |
| 마커 중심 추적 | OpenCV mask/moments 기반 추적 |
| 변위 계산 | `DisplacementZ` 생성 및 2048 길이 리샘플링 |
| 진행률 표시 | EventChannel 기반 처리 프레임/검출/실패 수 표시 |
| CSV 저장 | `Downloads/OpenCVDisplacement/`에 MediaStore 방식 저장 |
| CSV 공유 | Android 공유 시트 연결 |
| 모델 추론 | `Fwdcnn7.ptl` + PyTorch Mobile Lite |

Android 네이티브 채널:

```text
fault_diagnosis/file_metadata
fault_diagnosis/hsv_preview
fault_diagnosis/displacement
fault_diagnosis/displacement_progress
fault_diagnosis/model
```

### 3.3 iOS 구현

iOS에서도 Android와 같은 Flutter service API와 MethodChannel 계약을 유지하도록 구현했다.

| 기능 | 구현 상태 |
|---|---|
| Flutter UI 흐름 | Android와 동일한 `lib/` 코드 공유 |
| 첫 프레임/ROI 추출 | `AVAssetImageGenerator` 기반 |
| ROI 화면 표시 | `video_player` 대신 native 추출 프레임 이미지 사용 |
| HSV 미리보기 | iOS 첫 프레임 로딩 + Dart fallback 필터 |
| 마커 좌표 보정 | 정규화 중심 좌표와 추적 박스 비율 추가 |
| 변위 계산 | iOS OpenCV2 + Objective-C++ 브리지 |
| 진행률 표시 | iOS EventChannel 연결 |
| CSV 저장/공유 | Documents directory 저장 및 share sheet 연결 |
| 모델 추론 | iOS `LibTorch-Lite` + `Fwdcnn7.ptl` 연결 |

iOS 네이티브 구성:

- `OpenCV2` CocoaPod
- `LibTorch-Lite` CocoaPod
- `IOSDisplacementCalculator`
- `IOSDiagnosisCalculator`
- `AppDelegate.swift` MethodChannel/EventChannel 등록

## 4. 모델 및 데이터 계약

내장 모델은 Android/iOS 모두 같은 입력/출력 계약을 사용한다.

| 항목 | 값 |
|---|---|
| 모델 파일 | `Fwdcnn7.ptl` |
| 입력 | `DisplacementZ` |
| 입력 길이 | 2048 |
| 입력 shape | `[1, 1, 2048]` |
| 클래스 순서 | `B, H, IR, OR` |
| 후처리 | logits -> softmax -> 최대 확률 클래스 |

CSV 형식은 레거시 앱과 같은 형태를 유지한다.

```csv
# FPS: 240.0
Frame,Time(s),DisplacementX(px),DisplacementZ(px)
```

## 5. 주요 문제와 해결

### 5.1 Android Google Photos 파일명 문제

Google Photos 또는 content provider를 통해 영상을 선택하면 파일명이 숫자 ID처럼 표시되고 OpenCV 접근이 불안정할 수 있었다.

해결:

- Android 로컬 파일 선택기 기반으로 변경.
- 선택 영상을 앱 캐시로 복사.
- OpenCV에는 로컬 file path를 전달.
- 표시명은 가능한 경우 원본 metadata에서 복원.

### 5.2 모든 진단 결과가 H로 치우치던 문제

모델 자체보다 마커 검출 실패로 인해 `DisplacementZ`가 거의 0에 가까운 입력이 되는 문제가 원인이었다.

해결:

- 검출 성공/실패 프레임 수를 UI에 표시.
- `zStdDev`와 logits를 진단 화면에 노출.
- 검출 0건이면 진단 화면으로 넘어가지 않도록 방어.
- HSV 검출 품질을 시각적으로 확인할 수 있는 디버그 화면을 추가.

### 5.3 iOS ROI 흰 화면 문제

iOS에서 ROI 화면의 첫 프레임 표시가 `video_player` 기반일 때 흰 화면으로 보이는 문제가 있었다.

해결:

- ROI 화면 배경을 `HsvPreviewService.loadRoiFrame` 결과 이미지로 변경.
- iOS에서는 `AVAssetImageGenerator`로 첫 프레임을 추출해 Flutter로 전달.

### 5.4 Android/iOS 프레임 크기 차이

iOS 미리보기 프레임과 실제 OpenCV 처리 프레임의 크기가 다를 수 있었다.

해결:

- `MarkerInfo`에 정규화 중심 좌표와 추적 박스 비율을 추가.
- iOS 변위 계산 시 원본 프레임 크기에 맞춰 좌표를 복원할 수 있게 했다.

## 6. 검증 결과

### 6.1 Android 검증

검증 기기:

```text
SM S911N
Android 16 (API 36)
device id: R3CWB0JYD4A
```

수행한 검증:

```powershell
flutter analyze
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -S -W ...
```

최종 확인 결과:

- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- Android 실기기 APK 설치 성공.
- Android 실기기 앱 실행 성공.
- 사용자 확인 기준으로 Android 최종 동작 확인 완료.

### 6.2 iOS 검증

검증 기기:

```text
iPhone 12 mini
model: iPhone13,1
device id: 00008101-000620C61429003A
```

수행한 검증:

```bash
flutter analyze
flutter test
flutter build ios --release
xcrun devicectl device install app --device 00008101-000620C61429003A build/ios/iphoneos/Runner.app
```

최종 확인 결과:

- iPhone 12 mini에서 앱 설치/실행 확인.
- 영상 선택, ROI, HSV, 마커 중심, 변위 계산, 모델 진단 흐름 확인.
- 사용자 확인 기준으로 iOS 실기기 진단 흐름 1차 동작 확인 완료.

## 7. 현재 남은 확인 사항

최종 구현은 완료되었지만, 운영/연구 검증 관점에서 다음 항목은 추후 비교가 필요하다.

- 일부 IR 영상에서 iOS 결과가 OR로 판정된 사례가 있어 Android/iOS CSV와 logits 비교 필요.
- Android Gradle, Android Gradle Plugin, Kotlin 버전은 현재 빌드 가능하지만 향후 Flutter 지원 중단 경고가 있으므로 추후 업그레이드 필요.
- iOS 파일 선택은 현재 안정성 우선으로 기존 흐름을 유지하고 있으며, 필요 시 `UIDocumentPickerViewController` 기반 네이티브 파일 선택기로 고도화 가능.

## 8. 최종 결론

기존 Kotlin Android 앱의 핵심 결함 진단 기능은 Flutter 기반 앱으로 이전되었다.

현재 Flutter 앱은 Android와 iOS에서 같은 UI/상태 구조를 공유하며, 플랫폼별 네이티브 채널을 통해 OpenCV 영상 처리, CSV 저장/공유, PyTorch Lite 모델 추론을 수행한다.

Android 실기기와 iPhone 12 mini 실기기에서 각각 앱 설치와 실행, 주요 진단 흐름이 확인되었으므로, 본 프로젝트의 1차 Flutter 크로스 플랫폼 이전 구현은 완료 상태로 볼 수 있다.
