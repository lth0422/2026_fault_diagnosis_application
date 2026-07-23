# 관련 논문 정리 (Related Works)

카메라/영상 기반 회전기계·베어링 진단, 마커리스 변위 측정, 조명 강건성, 도메인 적응, 데이터 누수 관련 선행 연구를 모은다.

- 원문 PDF는 `papers/`에 보관(gitignore).
- 라이너 스콜라 1차 조사 결과 원본: `papers/liner_paper_list.csv` (30편, 블록 A~E 분류, 초록·인용수 포함).
- 아래 표는 CSV를 요약·재구성한 것. 촬영 사양 등 세부는 원문 확인 후 보강(⚠).

> 조사일: 2026-07-23. 검색 블록: A(마커리스 변위추출) / B(카메라 기반 진단) / C(촬영환경 강건성) / D(가변조건·도메인적응) / E(데이터 누수·평가신뢰성).

---

## 블록 A — 마커리스 영상 기반 변위·진동 추출

우리 연구와 가장 직접 겹치는 영역(우리는 마커 사용). 대부분 **phase-based motion / optical flow**로 마커 없이 변위 추출.

| # | 제목 | 출처 | 인용 | 핵심 | 대상 |
|---|------|------|-----:|------|------|
| A1 | Phase-Based Noncontact Vibration Measurement of High-Speed Magnetically Suspended Rotor | IEEE TIM, 2020 | 34 | 위상 변화를 직접 변위로 변환(위상 기울기 계산 생략) + 학습 기반 영상확대 | **회전기계**(자기부상 로터) |
| A2 | Camera-Based Micro-Vibration Measurement for Lightweight Structure using Improved Phase-Based Motion Extraction | IEEE Sensors J., 2020 | 53 | 변위→가속도 변환, 질량로딩 영향 없음, 카메라 파라미터/다운샘플링 효과 검증 | 경량 구조물 |
| A3 | Video Camera-Based Vibration Measurement for Civil Infrastructure | J. Infrastructure Systems, 2017 | **213** | motion magnification으로 175m 거리에서 0.21mm(1/170픽셀) 변위 식별 | 토목(안테나탑) |
| A4 | Phase-Based Vibration Frequency Measurement From Videos Recorded by Unstable Cameras | IEEE TIM, 2022 | 15 | **흔들리는 카메라**에서 카메라 운동 분리 + 특이스펙트럼 분석 | 실험실+야외 |
| A5 | Time-Varying Motion Filtering for Vision-Based Nonstationary Vibration Measurement | IEEE TIM, 2020 | 33 | PVMM을 **비정상 진동**으로 확장(TVMF), 시변 모드형상 시각화 | 이동질량계 |
| A6 | Visual vibration measurement of rotating shafts using optical flow enhanced by single-component image phase (SCIPOF) | NDT & E, 2026 | 0 | 협대역 필터로 단일성분 분리, **저SNR 강건**, 파라미터 자동선택 | **회전축** |
| A7 | Extracting sub-pixel displacement using visual vibrometry for NDE | J. Sound & Vibration, 2025 | 0 | 강제가진+phase-based로 **저프레임레이트 카메라**에서 0.65μm(1/200픽셀) | 캔틸레버(NDE) |
| A8 | Vision-Based Modal Analysis of Machine Tool Systems: Progress and Prospects | J. Flow Vis. Image Proc., 2024 | 0 | **서베이**: 마커 vs 기계 자체특징 기반 운동등록, 카메라 선택, 에일리어싱 회피 | 공작기계(리뷰) |

---

## 블록 B — 카메라 기반 베어링·회전기계 결함 진단

**핵심 경쟁군.** 대부분 산업용 고속카메라 또는 **이벤트 카메라** 사용. 스마트폰 아님 → 우리 차별점.

| # | 제목 | 출처 | 인용 | 카메라 | 방법·정확도 |
|---|------|------|-----:|--------|------|
| B1 | Intelligent Machinery Fault Diagnosis With Event-Based Camera | IEEE TII, 2024 | **170** | 이벤트 카메라 | 진동 이벤트 표현→DCNN, 데이터증강+표현클러스터링, 가속도계급 정확도 |
| B2 | Non-Contact Machine Vibration Sensing and Fault Diagnosis Based on Event Camera | IEEE, 2023 | 15 | 이벤트 카메라 | 누적프레임+Gabor필터→웨이블릿패킷+포락스펙트럼, 베어링 검증 |
| B3 | Vision-based non-contact vibration measurement and fault diagnosis of rolling bearings | Meas. Sci. Technol., 2025 | 4 | **고속비디오** | 복소 제어피라미드+프레임간 위상차→진동재구성→**Quadratic CNN**, 조명·노이즈 강건성 검증 |
| B4 | Dynamic Vision-Enabled Intelligent Micro-Vibration Estimation with Spatiotemporal Pattern Consistency | IEEE/CAA JAS, 2025 | 6 | 이벤트 카메라 | 시공간 패턴 일관성, 다중 ROI 융합 |
| B5 | Multimodal LLM-Enabled Machine Fault Diagnosis with Non-Contact Dynamic Vision Data | Sensors, 2025 | 11 | 이벤트 카메라 | Qwen2.5-VL-7B LoRA 미세조정, **3운전조건·4RPM, 정확도 95.4%** |
| B6 | Non-contact condition monitoring via phase-synchronized stroboscopic imaging | Struct. Health Monit., 2026 | 0 | **저가 이미징+스트로보** | 위상동기 스트로보+phase optical flow, 볼트풀림/불평형/축정렬불량 분류, **마커 사용** |

---

## 블록 C — 촬영환경(조명·흔들림·거리·각도) 강건성

우리 "촬영 환경" 한계에 직접 대응. **실험 설계 시 이 논문들의 강건성 평가 방법을 벤치마크로 삼을 것.**

| # | 제목 | 출처 | 인용 | 다룬 강건성 요소 |
|---|------|------|-----:|------|
| C1 | Line segment tracking for camera-based vibration measurement of large structures outdoors | MSSP, 2025 | 0 | **조명 변화** (DIC/LK 대비 ROI 내 조명 영향 최소화), 실외, 3D 변위 |
| C2 | Video-Based Micro-Vibration Measurement for Hydraulic Structures in Field Environments | Earthq. Eng. Resil., 2025 | 0 | ✅정독. 카메라 SH3-204, 1920×680, **1000fps**, 400mm 줌, 10~30m 거리, 25s. 6조건(촬영각도 side/flow/bottom × scale local/global)을 **상관계수**로 평가(Table3). **핵심 결론: ①조명이 가장 중요(불균일→추출 실패) ②local(근접/줌)≫global ③진동방향과 직각 촬영 필수**. side-local 상관 V0.95, bottom-global은 주파수 검출 실패 |
| C3 | Deep learning-based motion magnification and frames matching for structural displacement | Eng. Struct., 2025 | 2 | **저조도(low-light)**, 약한 텍스처, 이미지 노이즈. EulerMormer+Phase-ECC |
| C4 | Vision-Based Displacement Measurement for SHM: Metrology-Oriented Review of Uncertainty Quantification | Buildings, 2026 | 0 | **서베이**: 조명·카메라 흔들림·광학난류·플랫폼 운동 등 불확도 소스 체계적 정리 |

---

## 블록 D — 가변 운전조건·도메인 적응 + WDCNN 계열

우리 "단일 RPM" 한계 대응 + 모델 계보. **#D3가 우리 WDCNN과 직접 관련(원조 계열).**

| # | 제목 | 출처 | 인용 | 핵심 |
|---|------|------|-----:|------|
| D1 | A New Deep Transfer Learning Method for Bearing Fault Diagnosis Under Different Working Conditions | IEEE Sensors J., 2020 | **261** | CNN 전이학습, 다중 가우시안 커널 도메인 손실 |
| D2 | Deep Semi-supervised Domain Generalization Network under Variable Speed | IEEE TIM, 2020 | **174** | 가변속도, WGAN-GP 적대학습+의사라벨, 미지 속도로 일반화 |
| D3 | A deep CNN with new training methods (**TICNN**) under noisy environment and different working load | MSSP, 2018 | **1033** | ✅정독. **주의: WDCNN 아님 = TICNN**(WDCNN 후속작). 넓은 첫 커널(64×1)로 고주파 잡음 억제 + 커널 dropout + small mini-batch + ensemble. WDCNN은 baseline(도메인적응 avg 90%, TICNN 95.5%). **핵심: overlap 증강은 train만, test는 비중첩 유지→누수 방지** |
| D3′ | **A New Deep Learning Model … Good Anti-Noise and Domain Adaptation (WDCNN 원논문)** | Sensors, 2017 | - | ⚠ 우리 참고문헌 [2] = **우리 모델의 실제 원조.** 파일이 `papers/Block A/`에 오분류 보관됨. 미정독(다음 우선순위) |
| D4 | Deep Transfer Learning for Bearing Fault Diagnosis: A Systematic Review Since 2016 | IEEE TIM, 2023 | **475** | **서베이**: 라벨/기기/결함 관점 태스노미 |
| D5 | Bearing fault diagnosis under variable speed based on time series mixup and unsupervised DA | Meas. Sci. Technol., 2025 | 7 | 가변속도, 시계열 Mixup+비지도 도메인적응, 평균 92%+ |
| D6 | A bearing fault diagnosis integrating few-shot learning and transfer learning | Sci. Reports, 2025 | 4 | **Siamese-WDCNN** 퓨샷+전이, CWRU 사전학습→산업데이터 미세조정, 85~89% |

> ⚠ **모델 계보 정정:** 우리 모델(`Fwdcnn7.ptl`) = **WDCNN**, 원논문은 Zhang *Sensors* **2017** (참고문헌 [2], 파일은 Block A 폴더에 오분류). D3(*MSSP* 2018)은 그 **후속작 TICNN**으로 WDCNN을 baseline으로 쓴다. 두 편 다 인용 권장이나 **직접 원조는 Sensors 2017**.

---

## 블록 E — 데이터 누수·평가 신뢰성 (⭐ 정확도 방어 핵심)

**우리 99.7% 정확도의 정당성을 방어/재평가하는 데 필수.** 슬라이딩 윈도우+k-fold 조합의 위험을 직접 다룸.

| # | 제목 | 출처 | 인용 | 핵심 메시지 |
|---|------|------|-----:|------|
| E1 | **Impact of Data Leakage in Vibration Signals Used for Bearing Fault Diagnosis** | IEEE Access, 2024 | 5 | ✅정독. run-to-run/day-to-day(누수) vs **part-to-part(베어링 단위)** 비교 → 오차율 최소 0.39로 급등, 정확도 차 **최대 47%p**. KAt 55편 중 6편만 베어링 분리. 진동데이터의 "우수함"이 사실 베어링 재식별 누수일 수 있음 |
| E2 | Towards a more realistic evaluation of ML models for bearing fault diagnosis | MSSP 258, 2026 | 0 | ✅정독. 누수 3분류(segmentation / bearing-condition / bearing-repetition). **bearing-wise 분할 + multi-label 이진공식화 + Macro AUROC + Double-CV** 프로토콜 제안. 학습 베어링 다양성이 일반화 결정 요인. 코드공개 |
| E3 | Test-Training Leakage in Evaluation of ML for Condition-Based Maintenance | PHM Europe, 2024 | 3 | 훈련-테스트 분리 오류 리뷰 + 올바른 분할 가이드라인 |
| E4 | A Closer Look at Bearing Fault Classification Approaches | PHM Society, 2023 | 10 | 동일 베어링 데이터가 train/test에 걸치면 과도낙관. F-score 권장 |
| E5 | Benchmarking DL models for bearing fault diagnosis using CWRU: multi-label approach | arXiv, 2024 | 5 | CWRU 전통 분할의 누수 지적, 멀티라벨+prevalence-independent 메트릭(ROC) |
| E6 | Are Novel Deep Learning Methods Effective for Fault Diagnosis? | IEEE Trans. Reliability, 2025 | 5 | 통일 프레임워크로 8개 SOTA 재현→실제 응용 여전히 난제. 전처리 차이가 성능 왜곡 |

---

## 신규성(Novelty) 포지셔닝

| 축 | 선행 연구 대다수 | 우리 연구 |
|----|------------------|-----------|
| 카메라 | 산업용 고속카메라 / 이벤트 카메라 (고가) | **소비자용 스마트폰 240fps 슬로모션** |
| 기준점 | 마커리스(phase/optical flow) 추세 | 마커 부착 (한계, 개선 대상) |
| 배포 | 대부분 오프라인 후처리 | **온디바이스(Android/iOS 앱) End-to-End** |
| 대상 | 구조물(SHM) 다수 / 베어링은 산업카메라·이벤트카메라 | 베어링 4-class(B/H/IR/OR) |

**핵심 gap:** "스마트폰 슬로모션 + 베어링 결함 분류 + 온디바이스 DL"의 교집합은 희소.
**단, 저널 방어 조건 3가지:** ① 스마트폰 vs 산업카메라 성능 손실 정량화, ② 다조건 강건성(블록 C·D 기준), ③ 데이터 누수 없는 정직한 정확도(블록 E 기준).

---

## 웹 검색 보강 (Claude WebSearch, 라이너 CSV 미포함분)

라이너 CSV(30편)에 없지만 검색으로 확인된 논문. 원문 확보 시 위 블록 표에 편입.

### W-A. 영상 기반 진동/변위 (마커리스) — ScienceDirect 계열

| 제목 | 출처 | 관련 블록 | 비고 |
|------|------|-----------|------|
| A visual vibration characterization method for intelligent fault diagnosis of rotating machinery | MSSP, 2023 | A/B | ✅정독. **우리와 구조 최유사**(Gabor 위상차→1D변위→32×32 그레이스케일→2D-CNN, 4클래스 N/IR/OR/Roller). **차이: markerless(마커 아님, 베어링 seat 엣지) + 산업카메라 1000fps + 다속도 200~3000rpm(44 시퀀스)**. 정확도 99.792%(가속도계 92.76%보다↑). 단 클래스당 단일 베어링+슬라이딩윈도우+8:1:1 → **우리와 같은 누수 위험 내재** |
| Phase-based video vibration measurement and fault feature extraction for compound faults of rolling bearings | Adv. Eng. Inf., 2024 | A/B | **복합 결함** 대상 위상 기반 |
| Fast and accurate visual vibration measurement via derivative-enhanced phase-based optical flow | MSSP, 2023 | A | 미분 강화 위상 optical flow |
| Structural vibration measurement based on improved phase-based motion magnification and deep learning | MSSP, 2024 | A | 위상 모션확대+DL |
| Accuracy evaluation of sub-pixel structural vibration measurements through optical flow | Measurement, 2016 | A | 서브픽셀 정확도 벤치마크 |
| A visual measurement algorithm for vibration displacement of rotating body using semantic segmentation | Expert Syst. Appl., 2023 | A | 회전체, semantic segmentation |
| Vibration displacement measurement based on vision Gaussian fitting and edge optimisation for rotating shafts | Measurement, 2024 | A | 회전축, Gaussian fitting |

### W-B. 카메라 기반 진단 (추가)

| 제목 | 출처 | 비고 |
|------|------|------|
| Vision-based bearing fault diagnosis under non-stationary conditions using optimized short-time concentrated transform | RESS, 2025 | 고속카메라+LK optical flow, **비정상(가변 RPM)** 조건 |
| Dynamic Vision-Based Non-Contact Rotating Machine Fault Diagnosis with EViT | Sensors, 2025 | 이벤트카메라+Event Vision Transformer |
| Dynamic vision-based machine vibration sensing with signal alignment and feature clustering | Eng. Appl. AI, 2025 | 이벤트카메라 |
| Vibration Vision: Real-Time Machinery Fault Diagnosis with Event Cameras | ECCV workshop | 실시간 |
| Micro vibration detection for rotating machinery based on visual target detection (YOLO-MVD) | SIViP, 2025 | YOLO 미세진동 검출 |
| Image representation of vibration signals + CNN: a benchmark study | J. Vib. Control (SAGE), 2025 | 진동→이미지 변환 CNN 벤치마크 |
| Visual vibration measurement using intensity optical flow with optical field correction under uneven illumination | MSSP, 2025 | **조명(광원이동/다중광원/그림자) 강건성** — 블록 C |

### W-C. 스마트폰 카메라 계측 (novelty 직접 근거) ⭐

| 제목 | 출처 | 분야 | 비고 |
|------|------|------|------|
| Using a smartphone camera to analyse rotating and vibrating systems (SURVISHNO 2019 contest) | SURVISHNO, 2019 | 회전/진동 | **스마트폰 회전·진동 분석 경진대회** — 직접 관련 |
| Monitoring cantilever beam with a vision-based algorithm and smartphone | JVE/Extrica | SHM | 스마트폰 슬로모션 고유진동수 |
| A review of smartphone sensing for structural health monitoring | J. Civil SHM, 2025 | SHM 리뷰 | 스마트폰 센싱 종합 |
| Review on smartphone sensing technology for SHM | Measurement, 2023 | SHM 리뷰 | |
| A smartphone camera and built-in gyroscope for non-contact off-axis structural displacement | Measurement, 2020 | 구조 변위 | **자이로 보정으로 흔들림 대응** (우리 핸드헬드 한계 참고) |
| Non-contact smartphone-based monitoring of thermally stressed structures | Sensors, 2018 | 구조 | |
| Development of low-cost non-contact SHM system for rotating machinery | Sensors, 2018 | 회전기계 | 저비용 비접촉 |
| Smartphone rolling-shutter effect for rotational speed measurement | (조사중) | 회전속도 | 프레임레이트 초과 회전속도 측정 |

### W-D. 타 분야 스마트폰 초고속 카메라 (240fps 계측 신뢰성 근거)

| 제목 | 출처 | 분야 | 비고 |
|------|------|------|------|
| Validity and reliability of smartphone high-speed camera and Kinovea for velocity-based training measurement | 스포츠과학 | 스포츠 바이오메카닉스 | **240fps 스마트폰**이 기준장비와 거의 완전 일치 검증 — 타 분야 계측 타당성 근거 |

> 관찰: 영상 기반 베어링 진단(W-A/W-B)은 거의 다 **산업용 고속·이벤트 카메라**. 스마트폰 계측(W-C/W-D)은 거의 다 **구조물(SHM)·스포츠·회전속도**. → "스마트폰 슬로모션 + 베어링 결함 분류 + 온디바이스 DL" 교집합이 비어 있음(우리 위치 재확인).

---

## 다음 액션

- [ ] 블록별 ⭐ 논문 원문 확보 → `papers/`: **A3, B1, B5, C2, D3, E1, E2** 우선.
- [ ] 각 논문 촬영 사양(카메라/fps/해상도/거리/RPM/조명/마커/데이터분할/정확도) 표 채우기.
- [ ] E1/E2 방법으로 우리 데이터 **recording-wise 재분할 재평가** 실험 설계.
- [ ] 스마트폰 계측 선행(SURVISHNO 등) 원문 확보.
