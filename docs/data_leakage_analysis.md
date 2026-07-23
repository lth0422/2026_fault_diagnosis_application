# 데이터 누수 분석 및 정확도 재평가 설계

우리 논문의 **99.7% 정확도**가 신뢰할 수 있는지 검증하기 위해, 베어링 진단 분야의
데이터 누수(data leakage) 문헌 2편을 정독하고 우리 실험 구성에 적용해 분석한다.

- **E1** — Wheat et al., "Impact of Data Leakage in Vibration Signals Used for Bearing Fault Diagnosis," *IEEE Access*, 2024.
- **E2** — Vieira et al., "Towards a more realistic evaluation of ML models for bearing fault diagnosis," *MSSP* 258, 2026. (코드: github.com/gama-ufsc/bearing-data-leakage)

> 결론 먼저: **우리 99.7%는 데이터 누수로 부풀려졌을 가능성이 매우 높다.** 특히 우리는
> 클래스당 물리 베어링이 1개뿐이라, 현재 데이터만으로는 "결함 유형을 학습했다"는 것을
> 원리적으로 증명할 수 없다. 이것이 저널 확장의 핵심 과제다.

---

## 1. 두 논문의 핵심 (누수 유형 분류)

### E2의 누수 taxonomy (가장 명확)

| 유형 | 정의 | 우리 해당 여부 |
|------|------|----------------|
| **Segmentation-level leakage** | 같은 연속 녹화에서 나온 세그먼트(윈도우)를 train/test로 나눔. 겹치지 않아도 누수 — 모델이 결함 특징이 아니라 그 신호 고유의 시간적/신호적 아티팩트를 학습 | **해당 ⚠** (윈도우 중첩 1024로 더 심각) |
| **Bearing-level: condition-wise** | 같은 물리 베어링을 운전조건(부하/속도)별로 나눔. 베어링 고유 signature가 양쪽에 남아 여전히 누수 | 해당 가능 |
| **Bearing-level: repetition-wise (run-to-run)** | 같은 조건의 같은 베어링을 반복 분할. **가장 심각, 정확도 ~100%** | **해당 ⚠** |
| **해결책: bearing-wise split** | 물리 베어링을 train/test에 상호 배타적으로 배치 | **불가능** (클래스당 1개뿐) |

### E1의 정량적 증거 (IEEE Access 2024)

- 6개 진단법 × 2개 데이터셋(McMaster CMHT, Paderborn KAt)에 3가지 분할 비교.
- **run-to-run / day-to-day(누수 有)** vs **part-to-part(베어링 단위, 누수 無)**:
  - part-to-part로 바꾸면 **오차율이 최소 0.39까지 급등** (랜덤 추측 수준에 근접).
  - run-to-run 대비 정확도 차이 **최대 0.47(47%p)**.
- KAt 사용 55편 중 **6편만** 베어링 분리를 제대로 함. 10편은 혼합(최고 위험).
- 교훈: "진동 데이터가 결함 예측에 좋아 보이는 이유"가 실제 결함 포착 능력이 아니라
  **베어링 재식별(re-identification)을 통한 누수**일 수 있다.

### E2의 정량적 증거 (MSSP 2026)

- Toy 실험(Fig.1): 누수 평가에서는 고용량 모델(LR)이 **이론적 최댓값(90.3%)마저 초과** —
  이는 사실상 training 성능을 측정한 착시. 올바른(valid) 평가에서는 모델 순위가 뒤집힘.
- 2025년 논문 18편 조사: 8편 random, 9편 condition-wise(여전히 누수), 1편 미기재.
  보고 정확도 대부분 98~100% → **부풀려짐**.
- **학습 베어링 다양성(# unique bearings)이 일반화 성능의 결정적 요인.**

---

## 2. 우리 실험 구성 진단

### 우리 데이터 구성 (논문 기준)

| 항목 | 값 |
|------|------|
| 물리 베어링 | **클래스당 1개** (IR 1, OR 1, B 1, 정상 1 = 총 4개) |
| 촬영 | iPhone 12 Pro, 1920×1080, 240fps, 1200 RPM 단일 조건 |
| 증강 | 슬라이딩 윈도우 (창 2048, **중첩 1024**) → 1,060 샘플 |
| 평가 | **10-fold 교차검증** (베어링/녹화 단위 분리 없음으로 추정) |
| 결과 | WDCNN 99.7% |

### 진단: 두 유형의 누수가 동시에 존재

1. **Segmentation-level leakage (확정적)**
   - 같은 연속 영상에서 잘라낸 윈도우들이 10-fold의 train/test에 섞여 들어감.
   - 중첩 1024이면 인접 윈도우가 샘플의 50%를 공유 → 사실상 거의 동일한 샘플이 양쪽에.
   - 모델이 "IR 결함의 물리적 특징"이 아니라 "이 영상의 시간적 패턴"을 외울 수 있음.

2. **Bearing-level leakage (구조적)**
   - 클래스당 베어링이 1개 → 그 베어링의 고유 signature = 클래스 라벨과 완벽히 상관.
   - 모델이 "결함 유형"과 "이 특정 베어링"을 구분할 방법이 원리적으로 없음.
   - **bearing-wise split이 불가능** → 일반화 능력을 현재 데이터로는 증명 불가.

> 즉 우리 99.7%는 E1/E2 기준으로 **run-to-run + segmentation 누수가 겹친 최악의 낙관적 케이스**에
> 가깝다. "높아서 오히려 의심스럽다"는 교수님 직관이 문헌으로 뒷받침된다.

### 결정적 근거: WDCNN 저자 본인의 관행

우리 모델의 원조인 WDCNN/TICNN 저자(Zhang et al., MSSP 2018)조차 overlap 증강을 쓸 때
**"training 샘플만 중첩시키고 test 샘플끼리는 중첩이 없도록"** 명시적으로 분리했다
(D3 논문 Fig.4, 4.1절: *"the training samples are overlapped to augment data and there is no
overlap among the test samples"*). 즉 **중첩 증강 후 무작위 분할은 원저자도 피한 방식**이다.
만약 우리가 전체를 중첩 증강한 뒤 10-fold를 무작위로 나눴다면, 원조 논문 관행보다도
느슨한 평가가 된다. → 최소한 이 부분은 반드시 확인·수정해야 한다.

---

## 3. 정확도 재평가 설계 (현재 데이터로 가능한 것)

현재 데이터(클래스당 1 베어링)로도 **누수 정도를 드러내는** 실험은 가능하다.

### 실험 3-A: 분할 방식 비교 (누수 노출)

| 분할 | 방법 | 기대 |
|------|------|------|
| ① 기존 random 10-fold | 현재 방식 재현 | ~99.7% (baseline) |
| ② segment-wise (중첩 제거) | 윈도우 중첩 0 + 시간순 blocked split (앞 70% train / 뒤 30% test) | 하락 예상 |
| ③ recording-wise | 한 클래스에 영상이 여러 개면 영상 단위로 train/test 분리 | 더 하락 예상 |

- ①→②→③으로 갈수록 정확도가 떨어지면 **누수 확정**.
- 이 곡선 자체가 저널 논문의 정직한 기여(우리 시스템의 실제 성능 범위 제시).

### 실험 3-B: 평가지표 교체

- accuracy 대신 **balanced accuracy / Macro AUROC** (E2 권장, prevalence-independent).
- **multi-label 이진 공식화**: Inner/Outer/Ball 각각 독립 detector, 정상 = 전부 0.
  - 클래스 불균형·동시 결함 처리에 유리, 결함 신호를 다른 라벨의 true negative로 활용.

### 실험 3-C: 혼동행렬 + logits 분석

- 현행 앱의 IR→OR 오분류(Android/iOS)를 여기서 정량화.
- 경계 사례인지 누수 붕괴 시 특정 클래스가 무너지는지 확인.

---

## 4. 근본 해결 (저널을 위한 데이터 수집 — "한 방")

현재 데이터의 한계는 재분할로 **완화되지 않는다.** 베어링이 1개뿐이기 때문.

### 반드시 필요한 것: 클래스당 복수 물리 베어링

- 각 결함 유형(IR/OR/B)마다 **물리적으로 다른 베어링 여러 개**를 촬영.
- 그래야 **bearing-wise split**(E1의 part-to-part, E2의 bearing-wise)이 가능해지고,
  "모델이 특정 베어링이 아니라 결함 유형을 학습했다"를 증명할 수 있음.
- E2: 학습 베어링 개수가 일반화의 결정 요인 → 많을수록 좋음(최소 클래스당 3개 권장, 3:2 분할).

### 권장 평가 프로토콜 (E2 채택)

1. **Bearing-wise 분할** (물리 베어링을 train/test 배타적으로).
2. **Multi-label 이진 공식화** + **Macro AUROC**.
3. **Double Cross-Validation (CVM-CV)**: 내부 CV로 하이퍼파라미터, 외부 100 split로 성능 추정.
4. 공개 데이터셋(CWRU/PU/UORED) 교차 검증으로 방법론 타당성 확인.

---

## 5. 저널 스토리라인 제안

이 분석은 그 자체로 저널 기여가 될 수 있다:

> "기존 카메라 기반 베어링 진단(및 우리 예비 연구)이 보고한 ~99% 정확도는 데이터 누수로
> 부풀려졌을 수 있다. 우리는 스마트폰 영상 기반 파이프라인에서 이를 정량적으로 드러내고,
> bearing-wise 평가 프로토콜과 복수 베어링 데이터셋으로 **현실적인 성능**을 처음으로 보고한다."

- 이 방향은 블록 E 논문들(E1/E2/E4)의 문제의식을 **영상/스마트폰 도메인으로 확장**하는 것.
- 아직 카메라 기반 진단 분야에서 누수를 정면으로 다룬 논문은 드묾 → novelty.

### 보강 관찰: 최상위 유사 논문도 같은 함정

우리와 구조가 가장 유사한 *A visual vibration characterization method* (Peng et al., **MSSP 2023**,
99.792%)도 **클래스당 단일 베어링 + 슬라이딩 윈도우 + 8:1:1 무작위 분할** 구성이다. 즉
영상 기반 베어링 진단 분야의 최상위 논문(MSSP)조차 bearing-wise 평가를 하지 않았을 가능성이
높다. 이는 **위험이자 기회**다 — 우리가 이 분야에 올바른 평가 프로토콜을 처음 도입하면
방법론적 기여가 명확해진다. (단, Peng은 200~3000rpm 다속도라 우리보다 조건 다양성은 높음.)

---

## 6. 액션 아이템

- [ ] 논문/코드에서 실제 데이터 분할 방식 확인 (random 10-fold가 맞는지, 녹화 단위 분리 여부).
- [ ] 클래스당 영상 개수·녹화 세션 수 파악 (recording-wise 분할 가능 여부).
- [ ] 실험 3-A(분할 비교) 재현 → 누수 곡선 확보.
- [ ] 복수 베어링 추가 촬영 계획 수립 (클래스당 최소 3개 목표).
- [ ] E2 공개 코드(github.com/gama-ufsc/bearing-data-leakage) 참고해 평가 프로토콜 이식.
- [ ] 남은 블록 E 논문(E4 "A Closer Look", E5 CWRU multi-label) 정독으로 보강.

> 관련: [related_works.md](related_works.md) 블록 E, [research_gaps_and_limitations.md](research_gaps_and_limitations.md) 3.2절.
