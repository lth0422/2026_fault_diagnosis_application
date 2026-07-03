# 진단 모델 입출력 사양 (Model I/O Spec)

본 문서는 결함 진단 모델의 입력/출력 사양을 정의한다.
※ 1차 마일스톤에서는 **실제 모델 추론을 구현하지 않으며**, 아래 사양은 향후
데이터 구조 및 통합의 기준으로 사용한다.

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

### 입력 준비 시 고려사항 (향후 마일스톤)
- 변위 시계열의 길이가 2048 이 되도록 리샘플링/패딩/절단 처리 필요.
- 정규화(normalization) 방식은 학습 시점 기준과 일치시켜야 함.

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

> 위는 참조 구현 사실이며, Flutter 신규 앱의 최종 추론 방식(플랫폼별 엔진)은 이후 마일스톤에서 확정한다.

## 3. 1차 마일스톤에서의 취급

- `DisplacementResult` 모델은 변위 시계열(DisplacementZ 포함) 데이터를 표현한다.
- `DiagnosisResult` 모델은 클래스(B/H/IR/OR) 기준의 진단 결과를 표현한다.
- `DisplacementPage`, `FaultDiagnosisPage` 는 위 사양에 맞춘 **mock 데이터**로 동작한다.

## 4. 향후 통합 (Out of Scope, 이후 마일스톤)

- 온디바이스 추론 및 네이티브 연동은 이후 단계에서 진행한다.
  참조 Android 는 PyTorch Mobile Lite 를 사용하며, Flutter 신규 앱의 플랫폼별
  추론 방식(Android/iOS)은 이후 마일스톤에서 확정한다.
- 본 마일스톤에서는 모델 파일, 추론 코드, 네이티브 MethodChannel 을 포함하지 않는다.
