# 2026 결함 진단 애플리케이션 (Fault Diagnosis Application)

기존 Kotlin 기반 Android 결함 진단 애플리케이션을 **Flutter/Dart** 기반의
Android/iOS 크로스 플랫폼 애플리케이션으로 전환하는 프로젝트입니다.

## 개요

- **기존 앱**: Kotlin Android 앱 (참조 구현, reference implementation)
- **신규 앱**: Flutter/Dart 기반 크로스 플랫폼 앱
- **대상 플랫폼**: Android, iOS
- **초기 목표**: UI 화면 흐름(UI flow)과 데이터 구조(data structure) 정의에 집중

> ⚠️ 기존 Android 앱은 **참조용 구현**일 뿐이며, 본 저장소에서 수정하지 않습니다.

## 애플리케이션 화면 흐름

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

## 1차 마일스톤 범위 (Scope)

포함:
- 문서화
- UI 화면 흐름 및 페이지 네비게이션
- 기본 데이터 모델 정의

제외 (out of scope):
- OpenCV, Core ML, ONNX, PyTorch
- MethodChannel 등 네이티브 연동
- 실제 영상 처리 및 모델 추론

## 진단 모델 요약

- 모델 입력: **DisplacementZ**
- 입력 길이: **2048**
- 입력 형상(shape): **[1, 1, 2048]**
- 클래스 순서: **B, H, IR, OR**

자세한 내용은 [docs/model_io_spec.md](docs/model_io_spec.md) 참고.

## 문서 목록

| 문서 | 설명 |
|------|------|
| [PROJECT_PLAN.md](PROJECT_PLAN.md) | 프로젝트 목표, 마일스톤, 화면 흐름 |
| [REQUIREMENTS.md](REQUIREMENTS.md) | 기능/비기능 요구사항, 제약사항 |
| [CLAUDE.md](CLAUDE.md) | 저장소 작업 규칙 |
| [docs/android_activity_mapping.md](docs/android_activity_mapping.md) | Kotlin Activity → Flutter Page 매핑 |
| [docs/model_io_spec.md](docs/model_io_spec.md) | 진단 모델 입출력 사양 |
| [docs/development_log.md](docs/development_log.md) | 개발 로그 |
