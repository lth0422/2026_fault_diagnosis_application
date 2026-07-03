# 프로젝트 계획 (PROJECT PLAN)

## 1. 프로젝트 목표

기존 Kotlin Android 결함 진단 애플리케이션을 **Flutter/Dart** 기반의
Android/iOS 크로스 플랫폼 애플리케이션으로 전환한다.

- 기존 Android 앱은 **참조 구현(reference implementation)** 으로만 사용한다.
- 신규 앱은 Flutter/Dart로 새로 작성한다.
- 대상 플랫폼: **Android, iOS**.
- 초기 개발은 **UI 흐름과 데이터 구조 정의**에만 집중한다.

## 2. 애플리케이션 화면 흐름

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

각 페이지의 역할 개요:

| 페이지 | 역할 |
|--------|------|
| StartPage | 시작 화면 / 진입점 |
| VideoSelectPage | 진단 대상 영상 선택 |
| VideoInfoPage | 영상 정보(해상도, FPS, 프레임 수 등) 확인 |
| RoiSettingPage | 관심 영역(ROI) 설정 |
| MarkerColorPage | 마커 색상 지정 |
| HsvSettingPage | HSV 색상 범위 조정 |
| MarkerCenterPage | 마커 중심점 검출/확인 |
| DisplacementPage | 변위(Displacement) 계산 결과 표시 (mock) |
| FaultDiagnosisPage | 결함 진단 결과 표시 (mock) |

## 3. 마일스톤

### 마일스톤 1 — 문서화 및 골격 정의 (현재 단계)
- [x] 프로젝트 문서 작성 (README, PROJECT_PLAN, REQUIREMENTS, CLAUDE, docs/*)
- [ ] Flutter 프로젝트 골격 및 `lib/` 폴더 구조
- [ ] 9개 페이지 플레이스홀더 및 네비게이션
- [ ] 기본 데이터 모델 정의
- [ ] DisplacementPage / FaultDiagnosisPage 는 mock 데이터 사용

### 마일스톤 2 — 영상 처리 (예정)
- 영상 로드 및 프레임 접근
- ROI / HSV / 마커 검출 실제 로직
- 변위(DisplacementZ) 계산

### 마일스톤 3 — 모델 추론 (예정)
- DisplacementZ 기반 진단 모델 통합
- 입력 형상 `[1, 1, 2048]`, 클래스 `B, H, IR, OR`
- 온디바이스 추론(Core ML / ONNX 등) 및 네이티브 연동

## 4. 1차 마일스톤 범위

**포함**
- 문서화
- 페이지 네비게이션만 구현
- 기본 데이터 모델: DiagnosisSession, VideoInfo, RoiInfo, HsvRange, MarkerInfo, DisplacementResult, DiagnosisResult
- DisplacementPage, FaultDiagnosisPage 는 mock 데이터로만 동작

**제외 (Out of Scope)**
- OpenCV, Core ML, ONNX, PyTorch
- 네이티브 MethodChannel 연동
- 실제 영상 처리 및 모델 추론

## 5. 진단 모델 개요 (참고)

- 모델 입력: **DisplacementZ**
- 입력 길이: **2048**
- 입력 형상: **[1, 1, 2048]**
- 클래스 순서: **B, H, IR, OR**

세부 사양은 [docs/model_io_spec.md](docs/model_io_spec.md) 참고.
