# CLAUDE.md — 저장소 작업 규칙

이 문서는 본 저장소(`2026_fault_diagnosis_application`)에서 AI 어시스턴트 및
기여자가 지켜야 할 작업 규칙을 정의한다.

## 1. 프로젝트 성격

- 기존 **Kotlin Android 앱**을 **Flutter/Dart** 기반 크로스 플랫폼 앱으로 전환하는 프로젝트.
- 대상 플랫폼: **Android, iOS**.
- 초기 개발은 **UI 흐름과 데이터 구조 정의**에만 집중한다.

## 2. 필수 규칙

1. 모든 작업은 저장소 `/2026_fault_diagnosis_application` **내부에서만** 수행한다.
2. 저장소 외부의 파일을 생성/수정/삭제/이동/조회하지 않는다.
3. 기존 **Android 앱은 참조 구현(reference implementation)** 이며 수정하지 않는다.
4. 신규 앱은 **Flutter/Dart**로 작성한다.

## 3. 범위 규칙 (1차 마일스톤)

**해야 할 것**
- 문서화
- 깨끗한 Flutter 프로젝트 구조 및 `lib/` 폴더 구조 정의
- 페이지 플레이스홀더 및 **네비게이션만** 구현
- 기본 데이터 모델 정의:
  `DiagnosisSession`, `VideoInfo`, `RoiInfo`, `HsvRange`, `MarkerInfo`,
  `DisplacementResult`, `DiagnosisResult`
- `DisplacementPage`, `FaultDiagnosisPage` 는 **mock 데이터**만 사용

**하지 말아야 할 것 (Out of Scope)**
- OpenCV, Core ML, ONNX, PyTorch 구현
- 네이티브 **MethodChannel** 기능
- 실제 영상 처리 및 모델 추론

## 4. 화면 흐름

```
StartPage → VideoSelectPage → VideoInfoPage → RoiSettingPage →
MarkerColorPage → HsvSettingPage → MarkerCenterPage →
DisplacementPage → FaultDiagnosisPage
```

기존 Android Activity 와의 매핑은 [docs/android_activity_mapping.md](docs/android_activity_mapping.md) 참고.

## 5. 진단 모델 사양 (참고)

- 모델 입력: **DisplacementZ**
- 입력 길이: **2048**
- 입력 형상: **[1, 1, 2048]**
- 클래스 순서: **B, H, IR, OR**

세부 사항은 [docs/model_io_spec.md](docs/model_io_spec.md) 참고.

## 6. 작업 방식

- 큰 변경 전에는 단계별 계획을 세우고 승인을 받는다.
- 변경 후에는 변경된 파일 목록과 요약을 제공한다.
- 개발 진행 사항은 [docs/development_log.md](docs/development_log.md) 에 기록한다.
