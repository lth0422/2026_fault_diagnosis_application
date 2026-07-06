# 진단 모델 입출력 사양 (Model I/O Spec)

본 문서는 결함 진단 모델의 입력/출력 사양을 정의한다.
현재 Flutter Android 앱에서는 레거시 `Fwdcnn7.ptl` 모델을 PyTorch Mobile Lite로
실행한다. iOS 버전에서도 아래 입력/출력 계약을 유지하는 것을 목표로 한다.

## 1. 입력 (Input)

| 항목 | 값 |
|------|-----|
| 입력 데이터 | **DisplacementZ** (변위 시계열) |
| 입력 길이 (length) | **2048** |
| 입력 형상 (shape) | **[1, 1, 2048]** |
| 자료형 (권장) | float32 |

### 형상 해석
- `[1, 1, 2048]` = `[batch, channel, length]`
  - batch = 1 (한 번에 1개 샘플)
  - channel = 1 (단일 채널)
  - length = 2048 (DisplacementZ 시계열 길이)

### 입력 준비 시 고려사항
- 변위 시계열의 길이가 2048 이 되도록 리샘플링/패딩/절단 처리 필요.
- 정규화(normalization) 방식은 학습 시점 기준과 일치시켜야 함.
- 마커 검출이 0프레임이면 모델 추론을 수행하지 않는다.
- 검출 성공/실패 프레임 수와 DisplacementZ 표준편차를 함께 확인해 입력 품질을 판단한다.

## 2. 출력 (Output)

| 항목 | 값 |
|------|-----|
| 출력 형태 | 클래스별 점수/확률 (4개 클래스) |
| 클래스 순서 | **B, H, IR, OR** |

### 클래스 인덱스 매핑
| 인덱스 | 클래스 | 설명(참고) |
|--------|--------|------------|
| 0 | B  | 결함 유형 B |
| 1 | H  | 결함 유형 H |
| 2 | IR | 결함 유형 IR |
| 3 | OR | 결함 유형 OR |

> 클래스 인덱스는 반드시 위 순서(**B, H, IR, OR**)를 따른다.
> 결과 해석 시 인덱스와 레이블 매핑이 어긋나지 않도록 주의한다.

### 후처리
- 모델 출력은 logits 이며, **softmax** 를 적용해 확률로 변환한다.
- 최종 예측은 최대 확률 클래스. (참조 UI 규칙: 예상 결함이 **H 면 파랑, 그 외(B/IR/OR)는 빨강**으로 강조)

## 2-1. 참조 Android 구현 (legacy_android)

- 추론 엔진: **PyTorch Mobile (Lite)** — 모델 파일 `Fwdcnn7.ptl` (assets).
- 입력 텐서: `Tensor.fromBlob(floatArray, [1, 1, 2048])`.
- 입력 소스: DisplacementActivity 가 저장한 CSV 의 **DisplacementZ 열(4번째 열, index 3)** 에서 최대 2048개.
- 클래스: `["B", "H", "IR", "OR"]`.

> Flutter Android 앱은 현재 위 참조 방식과 동일하게 `Fwdcnn7.ptl`을 내장 asset으로 포함하고,
> Android 네이티브 MethodChannel에서 PyTorch Lite 추론을 수행한다.

## 3. Flutter Android 구현 상태

- `DisplacementResult` 모델은 DisplacementZ, CSV URI, 검출 프레임 수, 실패 프레임 수,
  Z 표준편차를 표현한다.
- `DiagnosisResult` 모델은 클래스(B/H/IR/OR) 확률과 logits를 표현한다.
- `DisplacementPage`는 Android OpenCV 네이티브 채널로 실제 변위를 계산한다.
- `FaultDiagnosisPage`는 Android PyTorch Lite 네이티브 채널로 실제 모델 추론을 수행한다.
- 비 Android 플랫폼은 iOS 구현 전까지 일부 서비스에서 fallback/mock 경로가 남아 있을 수 있다.

## 4. iOS 통합 예정 사항

- iOS에서는 동일한 입력/출력 계약을 유지한다.
- 모델 엔진 후보는 PyTorch Mobile iOS, Core ML 변환, ONNX Runtime iOS이다.
- Android와 iOS는 같은 DisplacementZ CSV를 입력으로 넣고 logits/softmax 결과를 비교한다.
