# Android Activity → Flutter Page 매핑

기존 Kotlin Android 앱의 각 `Activity` 를 신규 Flutter 앱의 `Page` 로 매핑한다.
기존 앱은 **참조 구현**이며, 아래 매핑은 화면 흐름과 역할을 옮기기 위한 기준이다.

## 1. 매핑 표

| 순서 | 기존 Android (Activity) | 신규 Flutter (Page) | 역할 |
|------|-------------------------|---------------------|------|
| 1 | StartActivity | StartPage | 시작 화면 / 진입점 |
| 2 | MainActivity | VideoSelectPage | 진단 대상 영상 선택 |
| 3 | VideoSizeActivity | VideoInfoPage | 영상 정보(해상도/FPS/프레임 수 등) 확인 |
| 4 | ROIActivity | RoiSettingPage | 관심 영역(ROI) 설정 |
| 5 | MarkerColorActivity | MarkerColorPage | 마커 색상 지정 |
| 6 | HSVActivity | HsvSettingPage | HSV 색상 범위 조정 |
| 7 | MarkerCenterActivity | MarkerCenterPage | 마커 중심점 검출/확인 |
| 8 | DisplacementActivity | DisplacementPage | OpenCV 기반 변위 계산, 진행률 표시, CSV 저장/내보내기 |
| 9 | FaultDiagnosisActivity | FaultDiagnosisPage | PyTorch Lite 모델 추론 및 결함 진단 결과 표시 |

## 2. 기존 Android 화면 흐름

```
StartActivity
  → MainActivity
    → VideoSizeActivity
      → ROIActivity
        → MarkerColorActivity
          → HSVActivity
            → MarkerCenterActivity
              → DisplacementActivity
                → FaultDiagnosisActivity
```

## 3. 신규 Flutter 화면 흐름

```
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

## 4. 화면별 주요 UI 요소 (legacy 참조)

Flutter 페이지는 아래 legacy 화면의 UI 흐름/구성을 참조하되, 현재 Android 앱에서는
OpenCV 변위 계산과 PyTorch Lite 추론까지 실제 구현되어 있다.

| Flutter Page | legacy 주요 UI 요소 | 다음 단계로 넘기는 데이터 |
|--------------|--------------------|--------------------------|
| StartPage | 시작 버튼 | - |
| VideoSelectPage | 로컬 영상 선택 버튼 | videoPath, sourceUri, displayName |
| VideoInfoPage | width/height/fps 입력 + 프리셋(1080p 세로/가로, 720p 세로/가로, FPS 120/240) + 확인 | width, height, fps |
| RoiSettingPage | 첫 프레임 위 사각형 드래그, 자르기/리셋/완료 | ROI(left,top,right,bottom) |
| MarkerColorPage | 색상 버튼 5종(BLUE/GREEN/WHITE/YELLOW/RED) → HSV 프리셋 | defaultHSVRange |
| HsvSettingPage | HSV 6개 슬라이더(H/S/V min·max) + 원본/검출 미리보기 + 검출 비율 + 확인 | hsvRange |
| MarkerCenterPage | 이미지 탭으로 마커 지정, ROI 크기 슬라이더(0~300, 기본5), 확인/되돌리기 | markerPoints |
| DisplacementPage | 진행률 표시, 검출/실패 프레임 수, CSV 저장/내보내기, 완료 후 추론 버튼 노출 | CSV, DisplacementZ, 검출 통계 |
| FaultDiagnosisPage | 예상 결함(색상 강조: H=파랑, 그 외=빨강) + 다른 결함 확률 + logits + 완료 | diagnosisResult, Start 로 복귀 |

## 5. 참고

- Android 의 `Activity` 간 데이터 전달(Intent extras)은 Flutter 에서
  `DiagnosisSession` 상태 객체로 대체한다.
- 화면 이동은 Flutter 의 named route 네비게이션으로 구현한다.
- 색상별 HSV 프리셋, 클래스 순서(B/H/IR/OR) 등 세부 값은 legacy 구현과 동일하게 맞춘다.
- 일반 알림은 하단 버튼과 겹치지 않도록 상단 MaterialBanner 방식으로 표시한다.
- iOS 실험 시 같은 화면 흐름과 MethodChannel 계약을 유지하는 것을 목표로 한다.
