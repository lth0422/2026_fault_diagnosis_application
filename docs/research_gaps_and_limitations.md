# 연구 한계 분석 및 학술 논문 확장 방향

본 문서는 "스마트폰 카메라를 활용한 비접촉식 지능형 회전기계 결함 진단 시스템"(정보공학회 포스터, 2024) 논문을 기반으로, 기존 접촉식·비접촉식 진단 방식의 한계와 본 연구의 한계를 정리하고, 학술 저널 논문으로 확장하기 위한 방향을 제시한다.

---

## 1. 본 연구 요약

### 1.1 핵심 구성

| 항목 | 내용 |
|------|------|
| 입력 | iPhone 12 Pro 240fps 슬로모션 영상 |
| 변위 추출 | OpenCV + HSV 마커 추적 → DisplacementZ 시계열 |
| 모델 | WDCNN (Wide-kernel Deep Convolutional Neural Network) |
| 입력 형상 | [1, 1, 2048] (DisplacementZ 리샘플링) |
| 출력 클래스 | B (볼), H (정상), IR (내륜), OR (외륜) |
| 배포 환경 | Android (PyTorch Mobile 1.13.1, API 26+), iOS (LibTorch-Lite) |

### 1.2 주요 결과

- WDCNN 평균 추론 정확도 **99.7 ± 0.3%** (10-fold 교차검증)
- ANN + RMS/Skewness/Kurtosis 통계 특성 방법 대비 우수
- 영상 기반 DisplacementZ의 FFT 주파수 특성이 접촉식 가속도계와 일치함을 검증 (1200 RPM 기준 20 Hz 피크 일치)
- 별도 장비 없이 스마트폰만으로 End-to-End 결함 진단 가능

---

## 2. 기존 방식의 한계

### 2.1 접촉식 센서 기반 방식 (진동/가속도계)

| 한계 | 설명 |
|------|------|
| 물리적 간섭 | 센서의 무게·크기가 대상 기계의 진동 특성을 변화시킬 수 있음 |
| 장착 제약 | 소형 기계, 고속 회전체, 접근이 어려운 설치 환경에서 부착 불가 |
| 유지 비용 | 고가의 압전 가속도계, 배선, 데이터 수집 장비 필요 |
| 실시간 모니터링 한계 | 센서 배선이 필요하므로 이동 점검이 어려움 |
| 데이터 의존성 | 신호처리 전문 지식 요구, 특성 추출 방법 선택에 따라 성능 편차 큼 |

**대표 문헌:**
- S. Nandi, H. A. Toliyat, and X. Li, "Condition monitoring and fault diagnosis of electrical motors—a review," *IEEE Trans. Energy Convers.*, vol. 20, no. 4, pp. 719–729, 2005. (본 논문 [1])
- I. Raouf, H. Lee, and H. S. Kim, "Mechanical fault detection based on machine learning for robotic RV reducer using electrical current signature analysis," *J. Comput. Des. Eng.*, vol. 9, no. 2, pp. 417–433, 2022. (본 논문 [3])

### 2.2 기존 카메라/광학 기반 비접촉 방식

| 방식 | 한계 |
|------|------|
| **레이저 도플러 진동계 (LDV)** | 장비 단가가 수천만 원 이상, 전문 운용 인력 필요, 이동성 부족 |
| **디지털 이미지 상관법 (DIC)** | 정밀 패턴 도포 및 고해상도 카메라 필요, 실시간 처리 어려움 |
| **광학 흐름(Optical Flow) 기반** | 텍스처가 없는 표면에서 불안정, 조명·카메라 흔들림에 민감 |
| **구조물 건전성 모니터링(SHM) 카메라 기법** | 주로 저주파 대역(토목 구조물) 대상, 고속 회전체 적용 사례 드묾 |
| **마커 기반 영상 추적** | 마커 부착이 필수 → 본 연구 포함 |

**조사 완료 문헌 (2026-07-23, 상세는 [related_works.md](related_works.md)):**

- **마커리스 변위 추출(phase-based/optical flow):** 최근 연구는 마커 없이 변위를 뽑는 방향으로 수렴 중.
  A visual vibration characterization method (MSSP 2023, 위상차→CNN, 우리와 최유사),
  Camera-Based Micro-Vibration for Lightweight Structure (IEEE Sensors J. 2020),
  Video Camera-Based Vibration for Civil Infrastructure (J. Infra. Sys. 2017, 213회 인용),
  SCIPOF for rotating shafts (NDT&E 2026, 저SNR 강건).
- **카메라 기반 베어링 진단(경쟁군):** 대부분 산업용 고속카메라 또는 **이벤트 카메라** 사용.
  Intelligent Machinery Fault Diagnosis with Event-Based Camera (IEEE TII 2024, 170회),
  Vision-based non-contact bearing diagnosis (Meas. Sci. Technol. 2025, 고속비디오+Quadratic CNN),
  Multimodal LLM + event camera (Sensors 2025, 3조건·4RPM, 95.4%).
- **핵심 관찰:** 위 연구 중 **소비자용 스마트폰을 쓴 사례는 사실상 없음.** 스마트폰 계측은 대부분
  구조물(SHM)·스포츠·회전속도 측정에 국한 → 우리 novelty 위치. (상세: related_works.md 신규성 포지셔닝)

---

## 3. 본 연구의 한계 (자체 분석)

아래 한계는 교수님이 제시하신 분류를 기반으로 세부 사항을 보강한 것이다.

### 3.1 마커 의존성

| 항목 | 내용 |
|------|------|
| **한계** | 형광 마커를 회전기계 표면에 직접 부착해야 함 |
| **현장 영향** | 고속 회전체에 마커가 이탈할 수 있음; 열·유체 환경에서 HSV 색상이 변질됨; 표면이 작거나 접근 불가한 경우 부착 불가 |
| **모델 의존성** | 마커 검출 실패(missedFrameCount) 시 DisplacementZ ≈ 0 → 모든 결과가 H(정상)로 쏠리는 현상 발생 (개발 중 확인된 실제 문제) |
| **선행 근거** | 최근 연구는 마커리스로 수렴(phase-based motion, optical flow). 저프레임레이트에서도 서브픽셀(1/200픽셀) 달성 사례 존재 (J. Sound Vib. 2025). → 마커 제거가 실현 가능한 방향임을 문헌이 뒷받침 |
| **향후 질문** | 마커 없이 어떻게 기준점을 잡을 것인가? phase-based motion extraction, 광학 흐름, 템플릿 매칭, Keypoint(ORB/SIFT) 검토 필요 |

### 3.2 정확도 신뢰성

| 항목 | 내용 |
|------|------|
| **한계** | WDCNN 99.7% 정확도는 동일 테스트베드에서 수집한 동질적 데이터에 대한 10-fold CV 결과임 |
| **데이터 규모** | 원시 데이터에 슬라이딩 윈도우(stride 1024, size 2048) 적용 후 1,060개 샘플 — 이는 표준 CWRU 베어링 데이터셋 대비 매우 소규모 |
| **독립 검증 부재** | 학습/검증에 사용하지 않은 완전 독립 테스트셋 평가 결과가 없음 |
| **⚠ 데이터 누수 위험** | 슬라이딩 윈도우(중첩 1024)로 만든 이웃 샘플이 10-fold의 train/test에 나뉘어 들어가면 **누수(leakage)**. 이 경우 99.7%는 과대평가일 가능성 큼 |
| **문헌 근거** | *Impact of Data Leakage in Vibration Signals* (IEEE Access 2024): 분할 방식만 바꿔도 **정확도 40%+ 하락**, 선행 55편 중 다수가 이 문제. *Towards a more realistic evaluation* (arXiv 2025): **bearing-wise 분할** 필요. *A Closer Look...* (PHM 2023): 동일 베어링이 train/test 걸치면 과도낙관 |
| **클래스 불균형** | B/H/IR/OR 각 샘플 수가 동일한지, 현실 운전 조건에서의 클래스 비율과 다른지 명시 안 됨 |
| **향후 질문** | **recording/bearing 단위 분할**로 재평가 시 정확도는? 독립 테스트셋(다른 날·조건)에서는? CWRU 등 공개 데이터셋 비교 가능한가? |

### 3.3 촬영 환경 의존성

| 항목 | 내용 |
|------|------|
| **단일 RPM** | 1200 RPM 고정 조건만 실험 — 가변 속도, 기동/정지 과도 구간 미평가 |
| **고정 조명** | 연속광(Continuous Light) 사용 → 형광등, 자연광, 역광 환경 미검증 |
| **카메라 고정** | 삼각대 고정 촬영 → 핸드헬드 흔들림, 촬영 각도 변화 미검증 |
| **단일 기기** | iPhone 12 Pro (240fps, 1920×1080) 만 사용 → 다른 기기·해상도·프레임레이트 미검증 |
| **거리 고정** | 특정 촬영 거리에서만 실험 → 거리 변화에 따른 마커 검출 안정성 미검증 |
| **배경 단순** | 실험실 배경 → 산업 현장의 복잡한 배경(기름, 먼지, 다른 기계) 미검증 |
| **문헌 근거(강건성 평가 방법)** | *Video-Based Micro-Vibration for Hydraulic Structures* (Earthq. Eng. Resil. 2025): 조명·각도·스케일 강건성 정량 평가, **균일조명 필수·직각 촬영 중요** 가이드라인 제시. *Line Segment Tracking* (MSSP 2025): 실외 조명변화 강건. *DL motion magnification* (Eng. Struct. 2025): **저조도** 대응. → 우리 강건성 실험의 벤치마크로 활용 |
| **향후 질문** | 거리·각도·조명·흔들림·해상도 변화에 얼마나 강한가? 위 논문들의 평가 프로토콜을 참고해 강건성 실험 설계 |

### 3.4 연구 수준 및 확장 필요성

| 항목 | 내용 |
|------|------|
| **현재 수준** | 정보공학회 포스터 — 시스템 구현과 개념 검증(PoC) 수준 |
| **모델 해석 부재** | WDCNN의 어떤 주파수 성분이 결함 판별에 기여하는지 분석 없음 (CAM, Grad-CAM 등 미적용) |
| **단일 테스트베드** | 특정 BLDC 모터 + 베어링 조합만 사용 — 일반화 능력 불명 |
| **비교 실험 제한** | ANN과 WDCNN만 비교 — 1D-CNN, LSTM, Transformer 등 최신 모델과의 비교 없음 |
| **도메인 적응 미검증** | 학습 도메인(촬영 조건)과 다른 도메인에서의 성능 저하 가능성 |
| **문헌 근거(가변조건·도메인적응)** | *Deep Transfer Learning under Different Working Conditions* (IEEE Sensors J. 2020, 261회), *Semi-supervised Domain Generalization under Variable Speed* (IEEE TIM 2020, 174회), *Deep Transfer Learning Review Since 2016* (IEEE TIM 2023, 475회). WDCNN 원논문은 *A deep CNN with new training methods* (MSSP 2018, 1033회) — 우리 모델 계보 인용 확보 |
| **주의** | 우리 논문 참고문헌 [2](Zhang, Sensors 2017)와 위 MSSP 2018은 같은 저자군의 자매 WDCNN 논문. 둘 다 인용 권장 |

---

## 4. 학술 저널 논문 확장 방향 ("한 방")

교수님 질문: *"학술 논문으로 확장하려면 어떤 한 방이 필요한가?"*

아래 방향 중 하나 또는 조합이 저널급 기여가 될 수 있다.

### Option A — 마커리스(Marker-free) 영상 기반 진단
- **핵심:** HSV 마커 없이 광학 흐름(Lucas-Kanade, Farneback) 또는 위상 기반 영상 처리(Phase-based Motion Magnification)로 변위 추출
- **기여:** 현장 적용성 획기적 향상, 마커 설치 불가 환경 대응
- **난이도:** 고속 회전체에서 특징점 유지가 어려움 → 핵심 연구 과제

### Option B — 다조건 강건성 평가 및 데이터셋 구축
- **핵심:** RPM 가변(600~3000), 촬영 거리·각도·조명 다양화, 다기종 스마트폰으로 체계적 실험
- **기여:** 논문에서 가장 취약한 "단일 조건" 문제 해결, 공개 데이터셋 기여 가능
- **난이도:** 실험 셋업 비용과 시간 필요

### Option C — 도메인 적응(Domain Adaptation) 적용
- **핵심:** 학습 조건(기기 A, 조명 X)과 테스트 조건(기기 B, 조명 Y)이 달라도 성능을 유지하는 모델
- **기여:** 실용성 강화, Transfer Learning / Domain Adversarial 기법 적용
- **관련 연구:** DANN (Domain-Adversarial Neural Network), MMD-based transfer

### Option D — WDCNN 해석 가능성 분석 (XAI)
- **핵심:** Grad-CAM, SHAP, 주파수 기여도 분석으로 모델이 어느 주파수 성분(특정 결함 주파수: BPFO, BPFI, BSF)을 보는지 시각화
- **기여:** 물리적 타당성 검증 + 블랙박스 해소 → 신뢰성 있는 진단 근거 제시
- **난이도:** 비교적 낮음, 기존 모델 유지하며 분석 추가

### Option E — 공개 데이터셋과 크로스 검증
- **핵심:** CWRU(Case Western Reserve University) 베어링 데이터셋에서 DisplacementZ와 유사한 1D 진동 신호에 동일 WDCNN 적용 후 비교
- **기여:** 본 시스템의 일반화 가능성 입증 또는 한계 명확화
- **난이도:** 낮음

---

## 5. 관련 논문 조사 현황

> 1차 조사 완료(2026-07-23). **전체 목록·요약·인용수는 [related_works.md](related_works.md)** 참조.
> 라이너 스콜라 30편(`papers/liner_paper_list.csv`) + Claude WebSearch 보강분.

### 5.1 반드시 확보할 핵심 논문 (블록별 ⭐)

| 블록 | 제목 | 출처 | 인용 | 왜 |
|---|---|---|---:|---|
| 공통/D | A deep CNN with new training methods (WDCNN) | MSSP 2018 | 1033 | 우리 모델 계보 원논문 |
| A/B | A visual vibration characterization method for intelligent fault diagnosis | MSSP 2023 | - | 우리와 구조 최유사(위상차→CNN) |
| A | Video Camera-Based Vibration for Civil Infrastructure | J. Infra. Sys. 2017 | 213 | 마커리스 대표 |
| B | Intelligent Machinery Fault Diagnosis With Event-Based Camera | IEEE TII 2024 | 170 | 비접촉 진단 선도(경쟁군) |
| B | Multimodal LLM + event camera (3조건·4RPM, 95.4%) | Sensors 2025 | 11 | 다조건 실험·정확도 비교 대상 |
| C | Video-Based Micro-Vibration for Hydraulic Structures | Earthq.Eng.Resil. 2025 | - | 조명·각도 강건성 프로토콜 |
| D | Deep Transfer Learning Review Since 2016 | IEEE TIM 2023 | 475 | 도메인적응 서베이 |
| E | Impact of Data Leakage in Vibration Signals | IEEE Access 2024 | 5 | 정확도 재평가 근거(40% 하락) |
| E | Towards a more realistic evaluation (bearing-wise split) | arXiv 2025 | - | 누수 없는 분할 방법 |

- CWRU Bearing Data Center (공개 데이터셋) — 표준 벤치마크, 비교 기준.

### 5.2 추가 조사 필요 (미확보)

- 스마트폰 계측 원문: SURVISHNO 2019 contest, cantilever-smartphone(JVE), smartphone+gyro(Measurement 2020).
- 타 분야 스마트폰 240fps 계측 신뢰성(스포츠 VBT) — novelty 근거 보강용.
- XAI×베어링: "explainable AI bearing fault WDCNN", Grad-CAM 적용 사례 추가 조사.

---

## 6. 논문 확장 시 보완해야 할 실험

| 보완 항목 | 현재 상태 | 필요 작업 |
|---|---|---|
| **⭐ 데이터 누수 재평가** | 슬라이딩 윈도우+10-fold (누수 위험) | **recording/bearing-wise 분할**로 재평가 → 99.7%의 실체 확인 (최우선) |
| 독립 테스트셋 | 없음 (CV만) | 다른 날·다른 조건에서 수집한 데이터로 평가 |
| RPM 다양화 | 1200 RPM 고정 | 600·1200·1800·2400·3000 RPM 등 다조건 |
| 조명 다양화 | 연속광 고정 | 형광등, 자연광, 저조도, 역광 조건 추가 |
| 촬영 기기 다양화 | iPhone 12 Pro | 다른 스마트폰(Android, 다른 FPS) |
| 카메라 흔들림 | 삼각대 고정 | 핸드헬드 조건 |
| 마커리스 비교 | 해당 없음 | 광학 흐름 기반 변위 추출 성능 비교 |
| 모델 해석 | 없음 | Grad-CAM, 주파수 기여도 분석 |
| CWRU 비교 | 없음 | 공개 데이터셋 기준 성능 비교 |
| Android/iOS 일관성 | 일부 불일치 (IR→OR 1건) | 플랫폼 간 logits 완전 비교 |

---

## 7. Android/iOS 플랫폼 교차 검증 이슈 (현행 앱 관련)

현재 앱에서 발견된 한계로, 논문 검증 실험 설계 시 반드시 고려해야 한다.

- iPhone 12 mini에서 IR 영상 1개가 OR로 오분류된 사례 발생
- Android와 iOS의 OpenCV 변위 계산 알고리즘이 미세하게 다를 수 있음 (`AVAssetReader` vs `VideoCapture`)
- 동일 영상에 대한 Android/iOS CSV(DisplacementZ 열) 및 logits 비교가 완료되지 않은 상태
- 이 차이가 모델 경계 사례인지 구현 차이인지 명확히 구분되어야 논문 실험 결과의 신뢰성이 확보됨

---

## 8. 관련 메모 / 미결 사항

- [x] 1차 문헌 조사 완료 (라이너 30편 + WebSearch) → [related_works.md](related_works.md)
- [ ] **데이터 누수 재평가**: recording/bearing-wise 분할로 정확도 재측정 (E1/E2 방법) — 최우선
- [ ] WDCNN 계열 원논문 2편 완독: Zhang *Sensors* 2017 [본 논문 2] + Zhang *MSSP* 2018 (1033회)
- [ ] 블록별 ⭐ 논문 원문 `papers/` 확보 후 촬영사양·정확도 비교표 작성
- [ ] CWRU 데이터셋 활용 가능성 검토 (클래스 매핑: B/IR/OR + Normal)
- [ ] 교수님과 논문 방향(A~E 중 어느 옵션) 협의
- [ ] 독립 테스트셋 수집 계획 수립 (다조건: RPM·조명·기기·각도)
- [ ] Android/iOS logits 비교 실험 (IR 오분류 케이스 우선)
