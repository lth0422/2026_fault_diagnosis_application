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
| 8 | DisplacementActivity | DisplacementPage | 변위 계산 결과 표시 (초기: mock) |
| 9 | FaultDiagnosisActivity | FaultDiagnosisPage | 결함 진단 결과 표시 (초기: mock) |

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

Flutter 페이지는 아래 legacy 화면의 UI 흐름/구성을 그대로 참조한다.
(1차 마일스톤에서는 컨트롤만 배치하고 실제 처리는 placeholder/mock)

| Flutter Page | legacy 주요 UI 요소 | 다음 단계로 넘기는 데이터 |
|--------------|--------------------|--------------------------|
| StartPage | 시작 버튼 | - |
| VideoSelectPage | 갤러리에서 영상 선택 버튼 | videoUri |
| VideoInfoPage | width/height/fps 입력 + 프리셋(1080p 세로/가로, 720p 세로/가로, FPS 120/240) + 확인 | width, height, fps |
| RoiSettingPage | 첫 프레임 위 사각형 드래그, 자르기/리셋/완료 | ROI(left,top,right,bottom) |
| MarkerColorPage | 색상 버튼 5종(BLUE/GREEN/WHITE/YELLOW/RED) → HSV 프리셋 | defaultHSVRange |
| HsvSettingPage | HSV 6개 슬라이더(H/S/V min·max) + 미리보기 + 확인 | hsvRange |
| MarkerCenterPage | 이미지 탭으로 마커 지정, ROI 크기 슬라이더(0~300, 기본5), 확인/되돌리기 | markerPoints |
| DisplacementPage | 진행률 표시 → 완료 후 추론 버튼 노출 | CSV(DisplacementZ) |
| FaultDiagnosisPage | 예상 결함(색상 강조: H=파랑, 그 외=빨강) + 다른 결함 확률 + 완료 | (Start 로 복귀, 스택 초기화) |

## 5. 참고

- Android 의 `Activity` 간 데이터 전달(Intent extras)은 Flutter 에서
  `DiagnosisSession` 상태 객체로 대체한다.
- 화면 이동은 Flutter 의 named route 네비게이션으로 구현한다.
- 색상별 HSV 프리셋, 클래스 순서(B/H/IR/OR) 등 세부 값은 legacy 구현과 동일하게 맞춘다.
- 1차 마일스톤에서는 UI 구성 + 네비게이션까지 구현하고, 실제 영상 처리/추론은
  이후 마일스톤에서 추가한다.
