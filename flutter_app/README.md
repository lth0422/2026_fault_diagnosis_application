# fault_diagnosis_application (Flutter)

결함 진단 애플리케이션의 Flutter 구현체입니다. Android/iOS 크로스 플랫폼 대상.

## 현재 구현 범위 (1차 마일스톤)

- ✅ 페이지 구조 (9개 페이지)
- ✅ 네비게이션 흐름
- ✅ 플레이스홀더 UI (각 페이지 제목 + "다음" 버튼)
- ✅ 기본 데이터 모델
- ✅ FaultDiagnosisPage 의 B/H/IR/OR mock 확률 표시
- ❌ 실제 영상 선택 / OpenCV / 네이티브 코드 / 모델 추론 (미구현, 향후 마일스톤)

## 화면 흐름

```
StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage →
MarkerColorPage → HsvSettingPage → MarkerCenterPage →
DisplacementPage → FaultDiagnosisPage
```

## 폴더 구조 (lib/)

```
lib/
 ├─ main.dart           앱 진입점
 ├─ app.dart            MaterialApp, 라우트, provider 설정
 ├─ pages/              9개 페이지
 ├─ models/             데이터 모델 (+ DiagnosisSession: ChangeNotifier)
 ├─ services/           서비스 계층 (mock / 스텁)
 ├─ platform/           네이티브 채널 래퍼 (스텁, 미연결)
 └─ widgets/            공용 위젯
```

## 네이티브 코드 위치

- **Android** 네이티브 코드: `android/` (예: `MainActivity.kt`)
- **iOS** 네이티브 코드: `ios/` (예: `AppDelegate.swift`)

1차 마일스톤에서는 커스텀 MethodChannel 을 구현하지 않으며,
`android/`, `ios/` 는 기본 Flutter 호스트 상태입니다.

## 실행 방법

이 스켈레톤은 Flutter 가 설치되지 않은 환경에서 수기로 작성되었습니다.
일부 생성 파일(예: Gradle wrapper, `Runner.xcodeproj`, 런처 아이콘,
`ios/Runner/Base.lproj` 스토리보드 등)은 포함되어 있지 않습니다.

로컬에서 아래를 실행해 생성 파일을 보완하세요. `flutter create .` 는
기존 `lib/`, `pubspec.yaml` 을 덮어쓰지 않습니다.

```bash
cd flutter_app
flutter create .          # 누락된 생성/플랫폼 파일 보완
flutter pub get
flutter analyze
flutter run
```
