# Claude Code 사용 가이드 (Android Studio 플러그인)

Android Studio에 Claude Code JetBrains 플러그인을 연결한 상태에서,
이 프로젝트를 효율적으로 다루는 방법을 정리한다.

---

## 1. Claude Code가 모르는 것 (매 세션마다 알려줘야 할 것)

Claude Code 플러그인은 **대화 컨텍스트가 세션마다 초기화**된다.
새 세션을 시작할 때 아래 문장을 복사해서 먼저 보내면 된다.

```
이 프로젝트는 기존 Kotlin Android 결함 진단 앱을 Flutter로 포팅하는 작업입니다.
- 작업 폴더: flutter_app/
- legacy_android/ 는 읽기 전용 참조 코드 (수정 금지)
- 상태 관리: provider 패키지, DiagnosisSession (ChangeNotifier)
- 9개 페이지 흐름: StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage
  → MarkerColorPage → HsvSettingPage → MarkerCenterPage → DisplacementPage → FaultDiagnosisPage
- 모델 입력: DisplacementZ [1,1,2048], 클래스: B/H/IR/OR
- 1차 마일스톤: UI 흐름 + mock 데이터만. OpenCV/PyTorch/MethodChannel 미구현.
CLAUDE.md와 docs/ 폴더를 먼저 읽어주세요.
```

---

## 2. 지시 방법 — 잘 되는 패턴

### 파일 수정 요청
```
flutter_app/lib/pages/video_info_page.dart 를 수정해줘.
[구체적으로 무엇을 바꾸고 싶은지]
```

### 새 기능 추가
```
flutter_app/lib/ 아래에 [기능] 을 추가해줘.
기존 DiagnosisSession 상태 객체를 사용하고,
named route 네비게이션 방식을 유지해줘.
```

### 레거시 참조
```
legacy_android/X-twice-app_integration/.../com/example/useopencvwithcmakeandkotlin/
의 [ActivityName].kt 를 참고해서 Flutter 쪽 [PageName]에 동일한 동작을 구현해줘.
legacy_android 파일은 수정하지 마.
```

### 에러 해결
```
flutter run 했더니 아래 에러가 났어:
[에러 메시지 붙여넣기]
flutter_app/ 기준으로 원인 찾아서 고쳐줘.
```

### 분석 / 설명 요청
```
flutter_app/lib/models/diagnosis_session.dart 이 어떻게 동작하는지 설명해줘.
```

---

## 3. 지시 방법 — 잘 안 되는 패턴 (피할 것)

| 나쁜 예 | 좋은 예 |
|---------|---------|
| "앱 고쳐줘" | "StartPage에서 버튼 누르면 VideoSelectPage로 이동 안 되는 거 고쳐줘" |
| "기능 추가해줘" | "HsvSettingPage에 슬라이더 값 실시간 미리보기 텍스트 추가해줘" |
| "레거시 참고해서 다 만들어줘" | "MarkerCenterActivity.kt 참고해서 MarkerCenterPage의 탭 좌표 저장 로직만 추가해줘" |
| "왜 안 돼?" (에러 없이) | 에러 메시지 전체를 붙여넣기 |

---

## 4. 자주 쓰는 명령 흐름

### 코드 변경 후 검증
```
flutter analyze         # 정적 분석 (No issues found 확인)
flutter run             # 기기에서 실행
```

Claude Code에게:
```
flutter analyze 결과가 아래야, 고쳐줘:
[analyze 출력 붙여넣기]
```

### 새 페이지 추가 시 체크리스트
Claude Code에게 한 번에 요청할 내용:
```
[PageName] 페이지를 추가해줘.
1. flutter_app/lib/pages/[page_name]_page.dart 생성
2. static const routeName = '/[route]' 포함
3. app.dart routes 맵에 등록
4. 이전 페이지에서 Navigator.pushNamed 연결
5. StepHeader, PrimaryButton 위젯 사용
```

---

## 5. 프로젝트 주요 파일 위치 (빠른 참조)

| 역할 | 경로 |
|------|------|
| 앱 진입점 | `flutter_app/lib/main.dart` |
| 라우트 등록 | `flutter_app/lib/app.dart` |
| 전역 상태 | `flutter_app/lib/models/diagnosis_session.dart` |
| 페이지들 | `flutter_app/lib/pages/` |
| 데이터 모델 | `flutter_app/lib/models/` |
| 서비스 (mock) | `flutter_app/lib/services/` |
| 공통 위젯 | `flutter_app/lib/widgets/` |
| 네이티브 채널 stub | `flutter_app/lib/platform/native_diagnosis_channel.dart` |
| 레거시 참조 | `legacy_android/X-twice-app_integration/.../com/example/useopencvwithcmakeandkotlin/` |
| Activity→Page 매핑 | `docs/android_activity_mapping.md` |
| 모델 I/O 사양 | `docs/model_io_spec.md` |

---

## 6. 현재 마일스톤 상태

| 항목 | 상태 |
|------|------|
| 문서화 | 완료 |
| Flutter 앱 골격 (9페이지) | 완료 |
| 네비게이션 흐름 | 완료 |
| mock DiagnosisResult / DisplacementResult | 완료 |
| 실제 영상 선택 (file_picker) | 미구현 |
| OpenCV ROI / HSV 처리 | 미구현 |
| 마커 추적 / 변위 계산 | 미구현 |
| PyTorch Mobile Lite 추론 연동 | 미구현 |
