# iOS 버전 실험 대비 문서

이 문서는 현재 Flutter Android 앱에서 구현한 결함 진단 흐름을 iOS에서 실험하기 위해 필요한 준비 사항을 정리한 문서이다.

## 1. iOS 이전의 기본 방향

Flutter UI와 상태 관리는 Android/iOS에서 최대한 공유한다.

공유 가능한 영역:

- 화면 흐름
- `DiagnosisSession`
- 데이터 모델
- ROI/HSV/마커 설정 UI
- 진단 결과 표시 UI
- CSV 형식
- 모델 입력/출력 사양

플랫폼별 구현이 필요한 영역:

- 영상 파일 선택 및 로컬 파일 접근
- 첫 프레임 추출
- OpenCV 기반 ROI/HSV/마커 추적
- CSV 저장 위치와 파일 공유
- 온디바이스 모델 추론 엔진

## 2. 현재 Android 네이티브 의존 영역

현재 Android 구현은 `MainActivity.kt`에 여러 MethodChannel이 모여 있다.

| 채널 | 역할 | iOS 대응 필요 |
|---|---|---|
| `fault_diagnosis/file_metadata` | 로컬 영상 선택, 캐시 복사, 파일명 복원 | 필요 |
| `fault_diagnosis/hsv_preview` | ROI 첫 프레임 crop, HSV 미리보기 | 필요 |
| `fault_diagnosis/displacement` | OpenCV 기반 마커 추적 및 변위 계산 | 필요 |
| `fault_diagnosis/displacement_progress` | 변위 계산 진행률 이벤트 | 필요 |
| `fault_diagnosis/model` | PyTorch Lite 모델 추론 | 필요 |

권장 방향:

- Flutter 쪽 service API는 유지한다.
- iOS에서는 같은 MethodChannel 이름과 같은 argument/result 구조를 구현한다.
- 이렇게 하면 Flutter UI 코드는 거의 수정하지 않고 iOS 실험이 가능하다.

## 3. iOS에서 다시 구현해야 하는 기능

### 3.1 영상 선택

Android 현재 방식:

- `ACTION_OPEN_DOCUMENT`
- 선택 영상을 앱 캐시로 복사
- OpenCV가 읽을 수 있는 로컬 path 사용

iOS 대응 후보:

- `UIDocumentPickerViewController`
- 또는 `PHPickerViewController`

권장:

- 우선 `UIDocumentPickerViewController` 사용.
- 선택한 파일을 앱 sandbox의 temporary/cache directory로 복사.
- Flutter에는 로컬 파일 path, 원본 URI/bookmark 정보, 표시명을 반환.

주의:

- iOS Photos 라이브러리에서 직접 가져온 asset은 실제 파일 path가 바로 없을 수 있다.
- Android에서 겪은 Google Photos 문제와 비슷하게, iOS도 sandbox 로컬 복사가 안정적이다.

### 3.2 첫 프레임 추출 및 ROI HSV 미리보기

Android 현재 방식:

- `MediaMetadataRetriever`로 첫 프레임 추출
- OpenCV `Mat`으로 crop
- HSV `inRange`
- PNG byte array를 Flutter로 반환

iOS 대응 후보:

- `AVAssetImageGenerator`로 첫 프레임 추출
- OpenCV iOS framework 사용
- `UIImage` ↔ `cv::Mat` 변환
- HSV `inRange` 결과를 PNG로 반환

필요한 iOS result 구조는 Android와 동일하게 맞춘다.

```text
bytes: Uint8List
width: int
height: int
detectedPixels: int
totalPixels: int
```

Flutter 화면은 원본 ROI 이미지와 검출 결과 이미지를 전환해서 보여주며, 검출 픽셀 수와 비율을 표시한다. iOS 구현도 동일한 값들을 반환해야 HSV 품질 디버그 화면을 그대로 사용할 수 있다.

### 3.3 변위 계산

Android 현재 방식:

- `VideoCapture`로 영상 프레임 순회
- ROI crop
- 추적 박스에서 HSV mask 적용
- 실패 시 전체 ROI fallback
- `BGR2HSV`, `RGB2HSV` fallback
- moments로 중심 추적
- `DisplacementZ` 2048 길이 리샘플링

iOS 대응 후보:

- OpenCV iOS `VideoCapture` 사용 가능 여부 확인
- 불안정하면 `AVAssetReader`로 프레임을 읽고 OpenCV `Mat`으로 변환

권장:

1. OpenCV iOS `VideoCapture`로 먼저 실험.
2. 안 되면 `AVAssetReader` 기반 프레임 읽기로 전환.

반환 구조는 Android와 동일하게 유지한다.

```text
displacementZ: List<double>
rawLength: int
detectedFrameCount: int
missedFrameCount: int
zStdDev: double
csvUri: String
csvDisplayName: String
```

진행률 이벤트 구조도 Android와 동일하게 유지한다.

```text
processed: int
total: int
progress: double
detected: int
missed: int
```

iOS에서는 `FlutterEventChannel`로 `fault_diagnosis/displacement_progress`를 구현한다. 프레임 처리 중 너무 자주 이벤트를 보내면 UI가 버벅일 수 있으므로 Android와 같이 일정 프레임 간격으로 전송하는 방식을 권장한다.

### 3.4 CSV 저장

Android 현재 위치:

```text
Downloads/OpenCVDisplacement/
```

iOS 권장:

- 앱 Documents directory에 저장.
- share sheet를 추가해 Flutter의 `CSV 내보내기` 버튼에서 파일을 공유한다.
- Flutter 화면에는 저장된 파일명과 앱 Documents 내 경로를 표시.

iOS CSV 형식은 Android와 동일하게 유지한다.

```csv
# FPS: 240.0
Frame,Time(s),DisplacementX(px),DisplacementZ(px)
```

### 3.5 모델 추론

Android 현재 방식:

- `Fwdcnn7.ptl`
- PyTorch Mobile Lite
- 입력 `[1, 1, 2048]`
- 출력 logits → softmax
- 클래스 순서 `B, H, IR, OR`

iOS에서 검토할 선택지:

| 선택지 | 장점 | 단점 |
|---|---|---|
| PyTorch Mobile iOS | 기존 `.ptl` 유지 가능성 | iOS 배포/빌드 설정 확인 필요 |
| Core ML 변환 | iOS 친화적, 성능 좋음 | 모델 변환/검증 필요 |
| ONNX Runtime iOS | 크로스 플랫폼 가능 | 앱 크기/빌드 설정 고려 |

권장 실험 순서:

1. 현재 `Fwdcnn7.ptl`을 iOS PyTorch로 로드 가능한지 확인.
2. 어렵거나 장기 유지가 불리하면 Core ML 변환을 검토.
3. 변환 후 Android 결과와 iOS 결과가 같은 입력에서 같은지 비교.

## 4. iOS 프로젝트 준비 체크리스트

### Flutter/iOS 기본

- macOS 개발 환경 준비.
- Xcode 설치.
- CocoaPods 설치.
- `flutter doctor`에서 iOS 항목 확인.
- 실제 iPhone 또는 iOS Simulator 준비.

### iOS 권한/설정

필요할 수 있는 `Info.plist` 항목:

- 파일 접근/문서 선택 관련 설명.
- Photos 접근을 사용할 경우 `NSPhotoLibraryUsageDescription`.
- 카메라를 사용할 경우 `NSCameraUsageDescription`.

현재는 문서 선택 기반으로 시작하면 Photos 권한을 최소화할 수 있다.

### UI/알림

- Flutter 화면의 일반 알림은 하단 SnackBar가 아니라 상단 MaterialBanner 방식으로 정리되어 있다.
- iOS에서도 하단 주요 버튼과 메시지가 겹치지 않도록 같은 방식을 유지한다.

### 네이티브 라이브러리

확인 필요:

- OpenCV iOS framework 추가 방식.
- PyTorch iOS 또는 대체 추론 엔진 추가 방식.
- iOS 빌드 시 framework 크기와 architecture 설정.

## 5. Android와 iOS 결과 비교 계획

iOS 실험 시 같은 영상 세트를 사용해 Android 결과와 비교한다.

비교 항목:

- 영상 파일명/결함 라벨 표시 여부.
- ROI 좌표.
- HSV 범위.
- HSV 검출 픽셀 수와 검출 비율.
- 마커 중심 좌표.
- 변위 계산 진행률 이벤트 정상 표시 여부.
- 검출 성공 프레임 수.
- 실패 프레임 수.
- DisplacementZ 표준편차.
- CSV 행 수와 값 범위.
- CSV share sheet 동작 여부.
- 모델 logits.
- 최종 softmax 확률.
- 예측 클래스.

추천 기록 표:

| 영상명 | 실제 결함 | 플랫폼 | 검출/전체 | 실패 | Z std | logits(B,H,IR,OR) | 예측 |
|---|---|---|---:|---:|---:|---|---|
| 예시.mp4 | IR | Android | 2040/2048 | 8 | 1.234 | ... | IR |
| 예시.mp4 | IR | iOS | 2038/2048 | 10 | 1.231 | ... | IR |

## 6. iOS 이전 시 예상 리스크

### OpenCV VideoCapture 호환성

iOS에서 OpenCV `VideoCapture`가 Android처럼 안정적으로 동작하지 않을 수 있다. 이 경우 `AVAssetReader` 기반으로 프레임을 읽어야 한다.

### 모델 엔진 차이

PyTorch Lite Android와 iOS PyTorch 또는 Core ML 변환 모델의 출력이 미세하게 다를 수 있다. 같은 `DisplacementZ` CSV를 입력으로 넣어 logits를 비교해야 한다.

### 파일 접근 방식 차이

iOS는 sandbox 정책이 강하므로, 선택 파일은 앱 내부로 복사해서 처리하는 방식이 안전하다.

### 앱 크기 증가

OpenCV와 모델 추론 엔진을 함께 넣으면 iOS 앱 크기가 커질 수 있다.

## 7. iOS 실험 우선순위

1. Flutter iOS 앱이 기본 화면 흐름으로 실행되는지 확인.
2. iOS 로컬 영상 선택 및 앱 캐시 복사 구현.
3. 첫 프레임 ROI 표시 구현.
4. HSV 미리보기 구현.
5. HSV 원본/검출 전환 및 검출 비율 표시 확인.
6. 마커 중심 설정 후 변위 계산 구현.
7. 변위 계산 진행률 EventChannel 구현.
8. CSV 저장 및 share sheet 내보내기 구현.
9. 모델 추론 구현.
10. Android/iOS 동일 영상 결과 비교.

## 8. iOS 구현 시 유지해야 할 계약

Flutter 쪽에서 기대하는 모델 입력과 결과 구조는 Android와 동일해야 한다.

모델 입력:

```text
DisplacementZ length = 2048
shape = [1, 1, 2048]
dtype = float32
```

클래스 순서:

```text
B, H, IR, OR
```

진단 결과:

```text
probabilities: List<double>
logits: List<double>
predictedLabel: max probability class
```

CSV:

```text
# FPS: ...
Frame,Time(s),DisplacementX(px),DisplacementZ(px)
```

진행률 이벤트:

```text
processed / total / progress / detected / missed
```

이 계약을 유지하면 Flutter UI와 Android/iOS 결과 비교가 쉬워진다.
