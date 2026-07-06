# Flutter Android 앱 이전 및 개발 일지

이 문서는 기존 Kotlin Android 결함 진단 앱을 Flutter 기반 Android 앱으로 이전하면서 진행한 작업을 Notion 정리용으로 요약한 문서이다.

## 1. 프로젝트 목적

기존 앱은 Kotlin Android 기반으로, OpenCV를 이용해 영상에서 ROI와 마커를 추적하고 변위 데이터를 만든 뒤 PyTorch Mobile Lite 모델로 결함을 진단한다.

이번 전환의 목적은 다음과 같다.

- 기존 Android 앱의 핵심 결함 진단 흐름을 Flutter 앱으로 이전한다.
- Android에서 먼저 실제 영상 처리와 모델 추론을 검증한다.
- 이후 같은 Flutter UI/상태 구조를 유지하면서 iOS 버전 실험으로 확장한다.

## 2. 기존 앱 핵심 흐름

레거시 앱 위치:

```text
legacy_android/X-twice-app_integration/
```

참조한 주요 Activity:

| 기능 | 레거시 Activity | Flutter Page |
|---|---|---|
| 시작 | `StartActivity.kt` | `StartPage` |
| 영상 선택 | `MainActivity.kt` | `VideoSelectPage` |
| 영상 정보 입력 | `VideoSizeActivity.kt` | `VideoInfoPage` |
| ROI 지정 | `ROIActivity.kt` | `RoiSettingPage` |
| 마커 색상 선택 | `MarkerColorActivity.kt` | `MarkerColorPage` |
| HSV 범위 설정 | `HSVActivity.kt` | `HsvSettingPage` |
| 마커 중심 설정 | `MarkerCenterActivity.kt` | `MarkerCenterPage` |
| 변위 계산 | `DisplacementActivity.kt` | `DisplacementPage` |
| 결함 진단 | `FaultDiagnosisActivity.kt` | `FaultDiagnosisPage` |

## 3. Flutter 앱 구조

신규 앱 위치:

```text
flutter_app/
```

주요 구조:

```text
lib/
├─ app.dart
├─ models/
├─ pages/
├─ services/
├─ platform/
└─ widgets/
```

상태 관리는 `provider`와 `DiagnosisSession`을 사용한다. 기존 Android 앱에서 Activity 간 Intent로 전달하던 데이터를 Flutter에서는 하나의 세션 객체에 저장한다.

## 4. 현재 구현된 전체 화면 흐름

```text
StartPage
  → VideoSelectPage
    → VideoInfoPage
      → RoiSettingPage
        → MarkerColorPage
          → HsvSettingPage
            → MarkerCenterPage
              → DisplacementPage
                → FaultDiagnosisPage
```

## 5. 주요 구현 내역

### 5.1 Android Gradle 및 Flutter 빌드 안정화

- Groovy/Kotlin Gradle DSL 혼재 문제 정리.
- Android Gradle Plugin, Gradle Wrapper, Kotlin 버전을 Flutter 빌드 가능한 조합으로 조정.
- 실제 기기 `SM S911N`에서 APK 빌드/설치/실행 확인.

### 5.2 실제 영상 선택

- 초기에는 `file_picker`를 사용해 영상을 선택했다.
- Google Photos가 개입되면 파일명이 숫자 ID처럼 표시되고 OpenCV 접근이 불안정할 수 있어 Android 네이티브 로컬 파일 선택기로 변경했다.
- 현재 Android에서는 `ACTION_OPEN_DOCUMENT + CATEGORY_OPENABLE` 기반 선택기를 사용한다.
- 선택한 영상은 앱 캐시의 `selected_videos` 폴더로 복사한 뒤 OpenCV가 읽을 수 있는 로컬 path로 처리한다.

### 5.3 영상 정보 자동 읽기

- `video_player`를 사용해 선택 영상의 해상도와 재생 시간을 읽는다.
- FPS는 사용자가 입력한다.
- 프리셋:
  - `1080 x 1920`
  - `1920 x 1080`
  - `720 x 1280`
  - `1280 x 720`
  - FPS `120`, `240`

### 5.4 ROI 지정

- 선택한 영상의 첫 프레임을 표시한다.
- 화면에서 드래그해 ROI 사각형을 지정한다.
- ROI는 정규화 좌표로 저장한다.
- 화면에는 실제 픽셀 기준 ROI 좌표도 표시한다.

### 5.5 HSV 마커 색상 설정

레거시 앱의 HSV 프리셋을 Flutter 앱에 반영했다.

| 색상 | H | S | V |
|---|---:|---:|---:|
| BLUE | 100-140 | 150-255 | 50-255 |
| GREEN | 35-85 | 150-255 | 50-255 |
| WHITE | 0-180 | 0-30 | 200-255 |
| YELLOW | 20-35 | 150-255 | 50-255 |
| RED | 160-180 | 150-255 | 50-255 |

### 5.6 OpenCV 기반 HSV 미리보기

- Android에 OpenCV 모듈을 연결했다.
- 레거시 OpenCV SDK를 읽기 전용 참조로 사용한다.
- `fault_diagnosis/hsv_preview` MethodChannel을 통해 첫 프레임 ROI crop과 HSV 필터 결과를 생성한다.
- HSV slider를 조정하면 검출 결과를 실시간으로 확인할 수 있다.
- 디버그 확인을 위해 원본 ROI 이미지와 HSV 검출 결과 이미지를 전환해서 볼 수 있다.
- 검출 픽셀 수, 전체 픽셀 수, 검출 비율을 수치와 막대로 표시한다.

### 5.7 마커 중심 및 추적 박스 설정

- ROI crop 이미지 위에서 마커 중심을 탭으로 지정한다.
- 중심은 십자가와 링으로 표시한다.
- 추적 박스 크기를 slider로 조정한다.
- 추적 박스는 이후 변위 계산에서 마커 검색 범위로 사용된다.

### 5.8 OpenCV 기반 변위 계산

Android 네이티브 채널:

```text
fault_diagnosis/displacement
```

Android 진행률 이벤트 채널:

```text
fault_diagnosis/displacement_progress
```

처리 흐름:

1. 선택 영상 로컬 path를 `VideoCapture`로 연다.
2. 각 프레임에서 ROI를 crop한다.
3. 이전 마커 중심 주변의 추적 박스에서 HSV mask를 적용한다.
4. mask moments로 마커 중심을 찾는다.
5. 추적 박스에서 찾지 못하면 전체 ROI에서 다시 탐색한다.
6. `BGR2HSV`와 `RGB2HSV`를 모두 시도해 색공간 차이를 보완한다.
7. Y 좌표 평균을 제거해 `DisplacementZ`를 만든다.
8. 모델 입력 길이 2048에 맞춰 리샘플링한다.

검출 실패 방지:

- 마커가 한 프레임도 검출되지 않으면 변위 계산 실패로 처리한다.
- `검출 0/2048` 상태로 진단 화면까지 넘어가지 않도록 수정했다.

진행률 표시:

- Android 네이티브 처리 중 EventChannel로 처리 프레임 수를 전송한다.
- Flutter `DisplacementPage`에서는 진행률 막대, 처리 프레임 수, 검출/실패 프레임 수를 실시간 표시한다.

### 5.9 CSV 저장

레거시 CSV 형식을 유지한다.

```csv
# FPS: 240.0
Frame,Time(s),DisplacementX(px),DisplacementZ(px)
0,0.0,...
```

Android 저장 위치:

```text
Downloads/OpenCVDisplacement/
```

Android 10 이상에서는 MediaStore 방식으로 저장한다.

CSV 내보내기:

- 변위 계산 완료 후 `CSV 내보내기` 버튼을 제공한다.
- Android 공유 시트를 통해 CSV 파일을 다른 앱으로 공유할 수 있다.

### 5.10 내장 모델 추론

모델 파일:

```text
flutter_app/android/app/src/main/assets/Fwdcnn7.ptl
```

Android 네이티브 채널:

```text
fault_diagnosis/model
```

추론 방식:

- PyTorch Mobile Lite 사용.
- 입력: `DisplacementZ`
- 입력 형상: `[1, 1, 2048]`
- 클래스 순서: `B, H, IR, OR`
- 모델 출력 logits에 softmax를 적용해 확률로 변환한다.

### 5.11 화면 알림 방식

- 초기에는 `SnackBar`를 사용했으나, 하단 `다음/확인/진단하기/완료` 버튼과 겹치는 문제가 있었다.
- 현재는 상단 `MaterialBanner` 기반 알림을 사용한다.
- 짧은 안내/오류 메시지는 화면 상단에 표시되고 자동으로 사라진다.

## 6. 검증한 항목

개발 중 반복적으로 확인한 명령:

```powershell
flutter analyze
flutter test
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -S -W ...
```

확인된 내용:

- Flutter 앱 빌드 성공.
- Android 실제 기기 설치 성공.
- 앱 실행 성공.
- 영상 선택, ROI 지정, HSV 미리보기, 마커 중심 설정 화면 동작 확인.
- 변위 계산 완료 확인.
- CSV 저장 및 모델 추론 연결 구현.
- 마커 검출 실패 시 진단으로 넘어가지 않도록 방어 로직 추가.
- 변위 계산 중 진행률 표시 확인.
- HSV 검출 품질 디버그 표시 확인.
- CSV 공유 버튼 구현 및 Android 공유 시트 연결 확인.

## 7. 발견한 문제와 대응

### 문제 1. Google Photos 선택 시 파일명이 숫자로 표시됨

원인:

- Google Photos 또는 Android provider가 원본 파일명 대신 내부 ID를 반환했다.

대응:

- Android 로컬 파일 선택기로 변경.
- 선택 영상은 앱 캐시로 복사해 OpenCV가 안정적으로 읽도록 처리.
- content URI와 표시명을 보존하고 MediaStore/metadata에서 이름 복원을 시도.

### 문제 2. 모든 진단 결과가 H로 나옴

원인:

- 실제 모델 문제가 아니라 마커 검출 실패로 `DisplacementZ`가 전부 0에 가까운 입력이 된 것이 원인이었다.
- 확인 지표: `검출 0/2048`, `실패 2048`, `Z 표준편차 0.000`.

대응:

- 변위 계산 결과에 검출 성공/실패 프레임 수와 Z 표준편차를 표시.
- 진단 화면에 logits를 표시.
- 검출 0이면 변위 계산 실패로 처리해 모델 추론을 막음.
- 추적 박스 실패 시 전체 ROI 재탐색 fallback 추가.

### 문제 3. OpenCV와 PyTorch Lite native library 충돌

원인:

- OpenCV와 PyTorch Lite가 모두 `libc++_shared.so`를 포함했다.

대응:

- Android packaging 설정에 ABI별 `pickFirst`를 추가했다.

## 8. 현재 남은 Android 개선 과제

- 모델 입력 전처리 스케일이 학습 시점과 완전히 같은지 검증.
- 파일명에 포함된 실제 결함명과 모델 예측 결과를 비교하는 테스트 로그 기능.
- 테스트용 영상 세트별 결과 표 작성.
- 변위 계산 진행률을 실제 사용자 영상에서 충분히 부드럽게 표시하는지 장시간 영상으로 확인.
- CSV 공유 대상 앱별 호환성 확인.

## 9. 핵심 파일 목록

| 역할 | 파일 |
|---|---|
| 앱 라우팅 | `flutter_app/lib/app.dart` |
| 전역 세션 | `flutter_app/lib/models/diagnosis_session.dart` |
| 영상 선택 | `flutter_app/lib/services/file_service.dart` |
| 영상 정보 | `flutter_app/lib/services/video_service.dart` |
| HSV 미리보기 | `flutter_app/lib/services/hsv_preview_service.dart` |
| 변위 계산 | `flutter_app/lib/services/displacement_service.dart` |
| 진단 추론 | `flutter_app/lib/services/diagnosis_service.dart` |
| Android 네이티브 처리 | `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt` |
| 모델 파일 | `flutter_app/android/app/src/main/assets/Fwdcnn7.ptl` |
| Android 빌드 설정 | `flutter_app/android/app/build.gradle.kts` |
