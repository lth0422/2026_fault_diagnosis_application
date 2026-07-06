# 2026 결함 진단 애플리케이션 (Fault Diagnosis Application)

기존 Kotlin 기반 Android 결함 진단 애플리케이션을 **Flutter/Dart** 기반의
Android/iOS 크로스 플랫폼 애플리케이션으로 전환하는 프로젝트입니다.

## 개요

- **기존 앱**: Kotlin Android 앱 (참조 구현, reference implementation)
- **신규 앱**: Flutter/Dart 기반 크로스 플랫폼 앱
- **대상 플랫폼**: Android, iOS
- **현재 상태**: Flutter Android에서 실제 영상 선택, ROI/HSV 설정, OpenCV 변위 계산,
  진행률 표시, CSV 저장/내보내기, PyTorch Lite 모델 추론까지 실험 구현

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

## 현재 Android 구현 범위

포함:
- Flutter 9단계 화면 흐름 및 provider 기반 세션 상태 관리
- Android 로컬 영상 선택 및 앱 캐시 복사
- 첫 프레임 기반 ROI 지정
- HSV 프리셋/수동 조정, OpenCV 미리보기, 원본/검출 디버그 표시
- 마커 중심/추적 박스 설정
- Android OpenCV 기반 변위 계산 및 진행률 표시
- CSV 저장 및 Android 공유 시트 내보내기
- Android PyTorch Lite `Fwdcnn7.ptl` 모델 추론
- 하단 버튼과 겹치지 않는 상단 알림 표시

다음 실험:
- iOS 버전에서 동일한 Flutter UI 흐름 유지
- iOS 네이티브 영상 처리/OpenCV/모델 추론 구현 검토

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
| [docs/flutter_android_migration_report.md](docs/flutter_android_migration_report.md) | Flutter Android 이전/개발 일지 |
| [docs/ios_porting_preparation.md](docs/ios_porting_preparation.md) | iOS 버전 실험 대비 문서 |
