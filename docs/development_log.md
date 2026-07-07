# 개발 로그 (Development Log)

프로젝트 진행 사항을 시간순으로 기록한다. 최신 항목이 위쪽에 오도록 작성한다.

---

## 2026-07-07 — iPhone 12 mini 실기기 iOS 진단 흐름 1차 확인

**작업 내용**
- iPhone 12 mini에서 Flutter iOS 앱 설치/실행을 반복 검증.
- iOS에서 영상 선택 → ROI 설정 → HSV 미리보기 → 마커 중심 설정 → 변위 계산 → 모델 진단 흐름을 1차로 확인.
- iOS ROI 첫 화면이 `video_player`에서 흰 화면으로 보이는 문제가 있어, ROI 설정 화면의 배경 프레임을 `HsvPreviewService.loadRoiFrame` 결과 이미지로 표시하도록 변경.
- iOS `fault_diagnosis/hsv_preview` 채널을 추가해 `AVAssetImageGenerator` 기반 첫 프레임 추출/ROI crop을 수행하도록 연결.
- iOS 미리보기 프레임과 실제 OpenCV 처리 프레임 크기가 다를 수 있어, 마커 중심과 추적 박스 크기를 ROI 프레임 기준 정규화 값으로 함께 저장하고 iOS 변위 계산에 전달하도록 보강.
- 파일명 복원 실험은 iOS 파일 경로/표시 안정성에 영향을 줘 롤백했고, 현재는 기존 `file_picker` 기반 선택 흐름을 유지한다.
- 현재 테스트 세트에서 대부분의 진단 결과는 기대값과 맞았으나, IR 영상 2개 중 1개가 iOS에서 OR로 판정되는 사례가 있어 Android/iOS CSV 및 logits 비교가 필요하다.

**생성/수정 파일**
- `flutter_app/ios/Runner/AppDelegate.swift`
- `flutter_app/lib/pages/roi_setting_page.dart`
- `flutter_app/lib/pages/marker_center_page.dart`
- `flutter_app/lib/models/marker_info.dart`
- `flutter_app/lib/services/hsv_preview_service.dart`
- `flutter_app/lib/services/displacement_service.dart`
- `docs/development_log.md`
- `docs/ios_porting_preparation.md`

**검증**
- `flutter analyze` 성공.
- `flutter build ios --release` 성공.
- `xcrun devicectl device install app --device 00008101-000620C61429003A build/ios/iphoneos/Runner.app` 성공.
- iPhone 12 mini에서 앱 첫 화면 및 주요 진단 흐름 진입 확인.
- 사용자 실기기 확인 기준으로 ROI/HSV/변위 계산/진단 흐름이 동작함을 확인.

**Android 영향 범위**
- 이번 iOS 작업 후 `flutter_app/android/` 하위 변경 사항은 없다.
- `flutter_app/lib/`는 Android/iOS 공통 코드이므로 일부 변경되었다.
  - `DiagnosisService`, `DisplacementService`, `HsvPreviewService`가 iOS에서도 네이티브 채널을 호출하도록 플랫폼 분기를 확장했다.
  - `MarkerInfo`에 정규화 좌표/박스 비율 필드를 추가했다.
  - Android 네이티브 채널에는 기존 인자와 함께 추가 인자가 전달되지만, Android `MainActivity.kt`는 필요한 키만 읽는 구조이므로 기존 Android 동작 계약은 유지된다.
- 커밋/푸시 전 Android 실기기 또는 최소 `flutter build apk --debug`로 회귀 확인하는 것이 안전하다.

**남은 검증**
- 같은 IR 영상에 대해 Android/iOS CSV의 `DisplacementZ`, `detectedFrameCount`, `missedFrameCount`, `zStdDev`, logits를 비교해야 한다.
- IR/OR logits 차이가 작으면 모델 경계 사례로 기록하고 유지하는 편이 낫다.
- 변위 통계가 Android와 크게 다르면 ROI 좌표계, 회전 메타데이터, HSV threshold, 프레임 추출 방식을 우선 점검한다.

---

## 2026-07-07 — iOS PyTorch Lite 모델 추론 연결

**작업 내용**
- Android와 같은 `Fwdcnn7.ptl` 모델 파일을 iOS Runner bundle resource로 추가.
- CocoaPods에 `LibTorch-Lite`를 추가해 iOS에서 PyTorch Lite 모델을 로드하도록 구성.
- `IOSDiagnosisCalculator` Objective-C++ 브리지를 추가.
- iOS `fault_diagnosis/model` MethodChannel을 `AppDelegate`에 등록.
- Android와 같은 입력/출력 계약을 유지.
  - 입력: `DisplacementZ`, 길이 2048, shape `[1, 1, 2048]`
  - 출력: logits, softmax probabilities, class labels `B, H, IR, OR`
- Dart `DiagnosisService`가 iOS에서도 mock 대신 네이티브 MethodChannel을 호출하도록 변경.
- PyTorch Lite 2.1 headers가 C++17을 요구해 iOS Runner target의 C++ 표준을 `gnu++17`로 변경.

**생성/수정 파일**
- `flutter_app/ios/Podfile`
- `flutter_app/ios/Podfile.lock`
- `flutter_app/ios/Runner/Fwdcnn7.ptl`
- `flutter_app/ios/Runner/IOSDiagnosisCalculator.h`
- `flutter_app/ios/Runner/IOSDiagnosisCalculator.mm`
- `flutter_app/ios/Runner/Runner-Bridging-Header.h`
- `flutter_app/ios/Runner/AppDelegate.swift`
- `flutter_app/ios/Runner.xcodeproj/project.pbxproj`
- `flutter_app/lib/services/diagnosis_service.dart`

**검증**
- `pod install` 성공.
- `dart format lib/services/diagnosis_service.dart` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build ios --no-codesign` 성공.
- `flutter build ios --release` 성공.
- `xcrun devicectl device install app --device 00008101-000620C61429003A build/ios/iphoneos/Runner.app` 성공.
- `xcrun devicectl device process launch ...`로 앱 시작 후 즉시 크래시가 없는 것을 확인.

**남은 검증**
- 실제 iPhone 시나리오에서 변위 계산 완료 후 `FaultDiagnosisPage`까지 진입해 iOS PyTorch Lite 추론이 성공하는지 확인해야 한다.
- 동일한 `DisplacementZ` 입력에 대해 Android와 iOS logits/softmax가 같은지 비교해야 한다.
- 만약 `.ptl`이 PyTorch Lite 2.1 런타임과 호환되지 않으면, PyTorch iOS 버전 조정 또는 Core ML 변환을 검토한다.

## 2026-07-07 — iOS OpenCV 변위 계산 채널 1차 연결

**작업 내용**
- iOS에서 실제 변위 계산을 수행하기 위해 CocoaPods에 `OpenCV2`를 추가.
- `IOSDisplacementCalculator` Objective-C++ 브리지를 추가해 OpenCV `VideoCapture`, HSV mask, morphology, moments 기반 마커 중심 추적을 구현.
- Android와 같은 `fault_diagnosis/displacement` MethodChannel 및 `fault_diagnosis/displacement_progress` EventChannel을 iOS `AppDelegate`에 연결.
- iOS 변위 계산 결과를 Android와 같은 구조로 반환하도록 맞춤.
  - `displacementZ`
  - `rawLength`
  - `detectedFrameCount`
  - `missedFrameCount`
  - `zStdDev`
  - `csvUri`
  - `csvDisplayName`
- iOS CSV 저장 위치를 앱 Documents directory로 설정.
- iOS `shareCsv` 호출 시 `UIActivityViewController`를 표시하도록 연결.
- Dart `DisplacementService`가 iOS에서도 mock 대신 네이티브 MethodChannel을 호출하도록 변경.
- 최초 구현에서 `SceneDelegate`에 채널을 등록했으나 현재 `Info.plist`가 scene manifest를 사용하지 않아 실제 실행되지 않았다. 이로 인해 `MissingPluginException(No implementation found for method computeDisplacement)`이 발생했고, 채널 등록 위치를 실제 실행되는 `AppDelegate`로 이동했다.

**생성/수정 파일**
- `flutter_app/ios/Podfile`
- `flutter_app/ios/Podfile.lock`
- `flutter_app/ios/Runner/IOSDisplacementCalculator.h`
- `flutter_app/ios/Runner/IOSDisplacementCalculator.mm`
- `flutter_app/ios/Runner/Runner-Bridging-Header.h`
- `flutter_app/ios/Runner/SceneDelegate.swift`
- `flutter_app/ios/Runner.xcodeproj/project.pbxproj`
- `flutter_app/lib/services/displacement_service.dart`

**검증**
- `pod install` 성공.
- `dart format lib/services/displacement_service.dart` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build ios --no-codesign` 성공.
- `flutter build ios --release` 성공.
- `xcrun devicectl device install app --device 00008101-000620C61429003A build/ios/iphoneos/Runner.app` 성공.
- `xcrun devicectl device process launch ...`로 앱 시작 후 즉시 크래시가 없는 것을 확인.
- `MissingPluginException` 수정 후 `flutter analyze`, `flutter test`, `flutter build ios --release`, iPhone 재설치 성공.

**남은 검증**
- iPhone에서 실제 영상 선택 → ROI → HSV → 마커 중심 → 변위 계산까지 사용자 시나리오로 실행해 OpenCV `VideoCapture`가 iOS 선택 영상 path를 안정적으로 읽는지 확인해야 한다.
- 만약 iOS OpenCV `VideoCapture`가 특정 mp4/Photos 파일을 열지 못하면, 문서에 적어둔 대로 `AVAssetReader`로 프레임을 읽고 OpenCV `Mat`으로 넘기는 방식으로 교체한다.
- iOS 모델 추론은 아직 mock 상태이므로 변위 계산 이후 결함 진단은 다음 단계에서 PyTorch iOS/Core ML/ONNX 중 하나로 연결해야 한다.

## 2026-07-06 — iPhone 12 mini iOS 실행 환경 점검

**작업 내용**
- macOS Flutter/iOS 개발 환경을 점검.
- `flutter doctor` 초기 상태에서 Xcode가 Command Line Tools로 잡혀 있고 CocoaPods가 없음을 확인.
- Homebrew로 CocoaPods `1.16.2` 설치.
- 현재 세션에서는 `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`를 지정해 Xcode 16.0을 사용.
- `flutter clean` 후 `flutter pub get`을 다시 실행해 오래된 `ios/Flutter/Generated.xcconfig`의 임시 Flutter SDK 경로를 현재 Mac 경로로 갱신.
- iOS 플러그인 의존성 설치를 위해 `pod install` 실행.
- `video_player_avfoundation`이 iOS 13.0 이상을 요구해 `ios/Podfile`의 최소 배포 타깃을 `12.0`에서 `13.0`으로 변경.
- 실제 iPhone 12 mini가 Flutter/Xcode에서 인식되는 것을 확인.
- Xcode signing 설정 후 iOS release 빌드와 기기 설치를 확인.

**확인된 기기**
- `고대호의 iPhone`
- 모델: `iPhone13,1` (iPhone 12 mini)
- iOS: `26.5`
- Flutter device id: `00008101-000620C61429003A`
- Xcode/CoreDevice 상태: `available (paired)`

**생성/수정 파일**
- `flutter_app/ios/Podfile`
- `flutter_app/ios/Podfile.lock`
- `flutter_app/ios/Runner.xcworkspace/contents.xcworkspacedata`
- `flutter_app/ios/Runner.xcodeproj/project.pbxproj` (Xcode signing/team 설정 및 Flutter 호환성 갱신)
- `flutter_app/ios/Flutter/Generated.xcconfig` (생성 파일, 현재 Mac 경로로 갱신)
- `flutter_app/ios/Flutter/flutter_export_environment.sh` (생성 파일, 현재 Mac 경로로 갱신)

**검증**
- `flutter pub get` 성공.
- `pod install` 성공.
- `flutter analyze` 성공.
- `flutter build ios --no-codesign` 성공.
- `flutter build ios --release` 성공.
- `xcrun devicectl device install app --device 00008101-000620C61429003A build/ios/iphoneos/Runner.app` 성공.
- iPhone 12 mini에서 앱 첫 화면 실행 확인.

**확인된 제한 사항**
- `flutter run` debug 실행은 iOS에서 debug FlutterEngine attach가 정상적으로 붙지 않아 앱이 즉시 종료되는 현상이 있었다.
- iPhone에서 개발자 프로파일/인증서를 신뢰한 뒤 release 앱이 실행되는 것을 확인했다.
- 현재 확인된 범위는 Flutter iOS 앱의 기본 화면 실행이다. iOS OpenCV/모델 추론 네이티브 구현은 아직 연결되지 않았다.
- 시스템 기본 Xcode 경로는 아직 `/Library/Developer/CommandLineTools`이므로, 영구 설정을 위해 사용자가 터미널에서 `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`를 1회 실행하는 것이 좋다.
- CocoaPods는 UTF-8 locale이 필요하므로 Flutter/iOS 명령 실행 시 `LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8`를 함께 지정하면 안정적이다.

## 2026-07-06 — 진행률 표시, HSV 디버그, CSV 공유, 상단 알림 개선

**작업 내용**
- 변위 계산 중 Android 네이티브에서 프레임 처리 진행률을 EventChannel로 전달하도록 구현.
- `DisplacementPage`에서 진행률 막대, 처리 프레임 수, 검출/실패 프레임 수를 실시간 표시.
- 변위 계산 완료 후 CSV 파일을 Android 공유 시트로 내보내는 버튼 추가.
- `HsvSettingPage`에 원본/검출 이미지 전환 컨트롤 추가.
- HSV 검출 픽셀 수, 전체 픽셀 수, 검출 비율을 막대와 수치로 표시.
- 하단 버튼과 겹치던 SnackBar 알림을 제거하고 상단 MaterialBanner 기반 알림으로 교체.

**생성/수정 파일**
- `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt`
- `flutter_app/lib/services/displacement_service.dart`
- `flutter_app/lib/pages/displacement_page.dart`
- `flutter_app/lib/pages/hsv_setting_page.dart`
- `flutter_app/lib/pages/video_select_page.dart`
- `flutter_app/lib/pages/video_info_page.dart`
- `flutter_app/lib/pages/roi_setting_page.dart`
- `flutter_app/lib/pages/marker_center_page.dart`
- `flutter_app/lib/widgets/top_notice.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.

## 2026-07-06 — 로컬 영상 선택기 및 H 쏠림 진단 지표 추가

**작업 내용**
- Android 영상 선택을 `file_picker` 기본 갤러리/포토 흐름 대신 네이티브 `ACTION_OPEN_DOCUMENT` 기반 로컬 파일 선택기로 교체.
- 선택된 영상은 앱 캐시(`selected_videos`)로 복사한 뒤 OpenCV가 읽을 수 있는 로컬 파일 path를 사용하도록 변경.
- 원본 content URI와 표시명을 보존하고, 가능한 경우 MediaStore/metadata에서 원본 영상명을 복원.
- 변위 계산 결과에 원본 프레임 수, 마커 검출 성공/실패 프레임 수, DisplacementZ 표준편차를 추가.
- 결함 진단 결과에 모델 softmax 전 logits를 추가해 모든 결과가 H로 치우치는 원인을 추적할 수 있도록 표시.

**생성/수정 파일**
- `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt`
- `flutter_app/lib/models/video_info.dart`
- `flutter_app/lib/models/displacement_result.dart`
- `flutter_app/lib/models/diagnosis_result.dart`
- `flutter_app/lib/services/file_service.dart`
- `flutter_app/lib/services/video_service.dart`
- `flutter_app/lib/services/displacement_service.dart`
- `flutter_app/lib/services/diagnosis_service.dart`
- `flutter_app/lib/pages/video_info_page.dart`
- `flutter_app/lib/pages/displacement_page.dart`
- `flutter_app/lib/pages/fault_diagnosis_page.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.

## 2026-07-06 — CSV 저장/내보내기 및 내장 모델 추론 연결

**작업 내용**
- 레거시 `DisplacementActivity`의 CSV 형식을 따라 변위 계산 완료 시 CSV를 저장하도록 구현.
- CSV 헤더를 `# FPS`, `Frame,Time(s),DisplacementX(px),DisplacementZ(px)` 형식으로 유지.
- Android 10 이상에서는 `Downloads/OpenCVDisplacement`에 MediaStore 방식으로 CSV를 저장.
- `DisplacementResult`에 CSV URI와 표시용 저장 위치를 추가하고, 변위 계산 완료 화면에 저장 위치를 표시.
- 레거시 `Fwdcnn7.ptl` 모델을 Flutter Android asset으로 포함.
- Android 앱에 `org.pytorch:pytorch_android_lite:1.13.1` 의존성과 `.ptl` 압축 제외 설정 추가.
- `fault_diagnosis/model` MethodChannel을 추가해 PyTorch Lite 모델 추론을 네이티브에서 실행.
- `DiagnosisService`와 `FaultDiagnosisPage`를 mock 결과 대신 실제 모델 추론 흐름으로 교체.
- OpenCV와 PyTorch Lite가 함께 가져오는 `libc++_shared.so` 중복 패키징 문제를 `pickFirst`로 해결.

**생성/수정 파일**
- `flutter_app/android/app/build.gradle.kts`
- `flutter_app/android/app/src/main/assets/Fwdcnn7.ptl`
- `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt`
- `flutter_app/lib/models/diagnosis_result.dart`
- `flutter_app/lib/models/displacement_result.dart`
- `flutter_app/lib/services/diagnosis_service.dart`
- `flutter_app/lib/services/displacement_service.dart`
- `flutter_app/lib/pages/displacement_page.dart`
- `flutter_app/lib/pages/fault_diagnosis_page.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.

## 2026-07-06 — Android OpenCV 기반 실제 변위 계산 구현

**작업 내용**
- `DisplacementPage`의 mock 진행률/데이터 생성을 제거하고 실제 변위 계산 요청 화면으로 교체.
- Android `fault_diagnosis/displacement` MethodChannel을 추가해 Flutter에서 네이티브 OpenCV 계산을 호출.
- 네이티브에서 선택 영상의 프레임을 읽고, ROI 내부의 마커 추적 박스에 HSV `inRange`와 morphology를 적용.
- mask moments로 마커 중심을 프레임별 추적하고, Y 좌표 평균을 제거한 DisplacementZ 시계열을 생성.
- 모델 입력 길이에 맞춰 DisplacementZ를 2048개 값으로 리샘플링해 `DiagnosisSession`에 저장.
- 계산 실패 시 화면에서 에러 메시지와 다시 계산 버튼을 표시하도록 처리.

**생성/수정 파일**
- `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt`
- `flutter_app/lib/services/displacement_service.dart`
- `flutter_app/lib/pages/displacement_page.dart`
- `flutter_app/lib/models/displacement_result.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.

## 2026-07-03 — ROI 첫 프레임 기반 마커 중심/추적 박스 설정 구현

**작업 내용**
- `MarkerCenterPage` 플레이스홀더를 실제 ROI 첫 프레임 기반 화면으로 교체.
- HSV 미리보기와 같은 `HsvPreviewService.loadRoiFrame()`을 사용해 선택 영상의 ROI crop 이미지를 표시.
- ROI 이미지 탭 위치를 ROI 이미지 픽셀 좌표로 변환해 마커 중심으로 저장.
- 점 대신 큰 십자가, 중심 링, 작은 흰색 중심점을 표시하도록 구현.
- 추적 박스 크기 슬라이더를 5~300px 범위로 제공하고, 움직일 때 파란 박스가 실시간으로 확대/축소되도록 구현.
- `되돌리기`로 현재 마커를 제거하고, `확인` 시 `DiagnosisSession.markers`에 중심 좌표와 추적 박스 크기를 저장.
- `MarkerInfo`에 `trackingBoxSize` 필드 추가.

**생성/수정 파일**
- `flutter_app/lib/models/marker_info.dart`
- `flutter_app/lib/pages/marker_center_page.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.

## 2026-07-03 — Android OpenCV 기반 HSV 미리보기 채널 연결

**작업 내용**
- Flutter Android 앱에 `:opencv` 얇은 라이브러리 모듈을 추가.
- `legacy_android/X-twice-app_integration/OpenCV`의 Java wrapper, resource, native `.so`를
  읽기 전용으로 참조하고 빌드 산출물은 `flutter_app/` 아래에 생성되도록 구성.
- OpenCV Kotlin helper(`MatAt.kt`)는 현재 Kotlin 2.0.21과 충돌해 컴파일 대상에서 제외하고,
  Java wrapper API만 사용하도록 구성.
- `MainActivity`에 `fault_diagnosis/hsv_preview` MethodChannel 추가.
- Android 네이티브에서 첫 프레임 ROI crop과 HSV `inRange` 필터를 OpenCV로 수행하도록 구현.
- Dart `HsvPreviewService`는 Android에서 네이티브 OpenCV 채널을 우선 사용하고,
  비 Android 환경에서는 기존 Dart 구현으로 fallback.
- OpenCV native library가 요구하는 `libc++_shared.so`가 APK에 포함되지 않아 앱 시작 시
  `UnsatisfiedLinkError`가 발생하던 문제를 수정.
- `:opencv` 모듈에서 레거시 OpenCV 빌드 산출물 중 `libc++_shared.so`만 빌드 디렉터리로
  복사해 패키징하도록 설정.

**생성/수정 파일**
- `flutter_app/android/settings.gradle.kts`
- `flutter_app/android/app/build.gradle.kts`
- `flutter_app/android/opencv/build.gradle`
- `flutter_app/android/app/src/main/kotlin/com/example/fault_diagnosis_application/MainActivity.kt`
- `flutter_app/lib/services/hsv_preview_service.dart`
- `docs/development_log.md`

**검증**
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell am start -S -W ...`로 앱 실행 성공.
- `adb logcat -b crash`에서 OpenCV 로딩 crash가 사라진 것을 확인.
- `adb shell screencap`으로 Flutter 시작 화면 표시 확인.

## 2026-07-03 — 첫 프레임 ROI HSV 실시간 미리보기 구현

**작업 내용**
- `video_thumbnail` 패키지로 선택 영상의 첫 프레임을 추출하도록 구현.
- `image` 패키지로 첫 프레임에서 ROI 영역을 잘라내고 HSV 범위 필터를 적용하는
  `HsvPreviewService` 추가.
- 레거시 `HSVActivity`의 처리 흐름처럼 HSV 범위 안에 들어온 픽셀만 원본 색으로 남기고,
  나머지는 검정색으로 표시.
- `HsvSettingPage`에 ROI HSV 미리보기 영역을 추가.
- H/S/V `RangeSlider`를 움직이면 debounce 후 실시간으로 미리보기 이미지를 다시 계산.
- 미리보기 이미지 위에 검출 픽셀 비율을 표시.

**생성/수정 파일**
- `flutter_app/pubspec.yaml`
- `flutter_app/pubspec.lock`
- `flutter_app/lib/services/hsv_preview_service.dart`
- `flutter_app/lib/pages/hsv_setting_page.dart`
- `docs/development_log.md`

**검증**
- `flutter pub get` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

## 2026-07-03 — 레거시 HSV 프리셋 기반 설정 화면 보강

**작업 내용**
- 레거시 Android 앱의 마커 색상별 HSV 프리셋을 Flutter 마커 색상 선택 흐름에 명확히 연결.
- 선택한 마커 색상의 key/라벨과 HSV 프리셋을 `DiagnosisSession`에 함께 저장하도록 보강.
- HSV H 범위를 레거시 프리셋과 맞춰 0~180으로 조정.
- `HsvSettingPage`에서 선택한 마커 색상, 영상명, ROI 픽셀 좌표, 현재 HSV 범위를 표시.
- H/S/V 각각을 `RangeSlider`로 조정하도록 변경해 min/max 역전 입력을 방지.
- 색상 선택 버튼에 각 프리셋의 H/S/V 범위를 함께 표시.

**생성/수정 파일**
- `flutter_app/lib/models/diagnosis_session.dart`
- `flutter_app/lib/models/hsv_range.dart`
- `flutter_app/lib/pages/marker_color_page.dart`
- `flutter_app/lib/pages/hsv_setting_page.dart`
- `docs/development_log.md`

**검증**
- `dart format` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

## 2026-07-03 — 실제 영상 기반 ROI 사각형 지정 구현

**작업 내용**
- `RoiSettingPage`에서 선택한 영상을 `VideoPlayerController.file`로 초기화해 첫 프레임을 표시.
- 영상 위에서 드래그해 ROI 사각형을 지정하도록 구현.
- ROI 좌표는 프레임 크기와 독립적인 0.0~1.0 정규화 값(`RoiInfo`)으로 저장.
- 선택된 ROI의 픽셀 좌표(left/top/right/bottom)를 화면에 표시.
- `자르기` 버튼은 ROI 바깥 영역을 어둡게 표시하는 미리보기 토글로 구현.
- `리셋` 버튼으로 ROI 선택을 초기화하고, `완료` 시 `DiagnosisSession.roiInfo`에 저장 후 다음 화면으로 이동.
- `RoiPainter`가 실제 영상 위 overlay로 사용할 수 있도록 배경 표시 여부와 ROI 외부 dim 옵션을 추가.

**생성/수정 파일**
- `flutter_app/lib/pages/roi_setting_page.dart`
- `flutter_app/lib/widgets/roi_painter.dart`
- `docs/development_log.md`

**검증**
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

## 2026-07-03 — 영상 메타데이터 자동 입력 구현

**작업 내용**
- `video_player` 패키지를 추가해 선택한 영상의 가로/세로/길이 정보를 읽도록 구현.
- `VideoService.loadVideoInfo()`에서 선택한 영상 파일을 초기화하고 `VideoInfo`에
  width, height, durationMs를 채워 반환.
- `VideoInfoPage` 진입 시 선택된 영상의 메타데이터를 자동으로 읽어 가로/세로 입력칸에 반영.
- 영상 정보 입력 확인 시 기존 영상 path/displayName/durationMs를 유지하고, FPS가 입력되면
  durationMs 기준으로 frameCount를 계산.
- 메타데이터 읽기 실패 시 직접 입력 안내 메시지를 표시.

**생성/수정 파일**
- `flutter_app/pubspec.yaml`
- `flutter_app/pubspec.lock`
- `flutter_app/lib/services/video_service.dart`
- `flutter_app/lib/pages/video_info_page.dart`
- `docs/development_log.md`

**검증**
- `flutter pub get` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

## 2026-07-03 — 실제 영상 선택 1단계 구현

**작업 내용**
- `file_picker` 패키지를 추가해 Flutter 앱에서 실제 영상 파일을 선택할 수 있도록 구현.
- `VideoSelectPage`에서 영상 선택 버튼을 실제 파일 선택기로 연결.
- 선택한 영상 파일명을 화면과 SnackBar에 표시하고 `DiagnosisSession.videoInfo`에 저장.
- `VideoInfoPage`에서 선택된 영상명을 표시하고, 해상도/FPS 입력 시 기존 영상 경로/파일명을 유지.
- `VideoInfo` 모델에 `displayName` 필드 추가.
- 앱 프로젝트 재현성을 위해 `pubspec.lock`을 버전 관리 대상에서 제외하지 않도록 `.gitignore` 정리.

**생성/수정 파일**
- `flutter_app/pubspec.yaml`
- `flutter_app/pubspec.lock`
- `flutter_app/.gitignore`
- `flutter_app/lib/models/video_info.dart`
- `flutter_app/lib/services/file_service.dart`
- `flutter_app/lib/pages/video_select_page.dart`
- `flutter_app/lib/pages/video_info_page.dart`
- `docs/development_log.md`

**검증**
- `flutter pub get` 성공.
- `flutter analyze` 성공.
- `flutter test` 성공.
- `flutter build apk --debug` 성공.
- `adb install -r build/app/outputs/flutter-apk/app-debug.apk` 성공.
- `adb shell monkey -p com.example.fault_diagnosis_application 1`로 앱 실행 성공.

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
