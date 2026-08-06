# 음향-영상 멀티모달 결함 진단 — 관련 연구 및 연구 갭

라이너 스콜라 조사(2026-08) + 원본 CSV `papers/multimodal_paper_list.csv`(16편) + 우리 D1 오디오 실증([audio_feasibility_analysis.md](audio_feasibility_analysis.md))을 종합.
**질문: "카메라(영상) + 마이크(음향)를 함께 써서 베어링/기계 결함을 진단한 연구가 있나? 스마트폰으로는?"**

> **결론: 스마트폰 카메라+마이크 동시 활용은 Lu et al. 2016 [1] 단 한 편.** 그마저 신호처리(나눗셈)에 머물고 딥러닝 융합·변위 스펙트럼 미사용.
> **"스마트폰 영상(마커/마커리스 변위) + 스마트폰 음향(고주파 결함) + 딥러닝 융합"으로 베어링을 분류한 연구는 문헌에 없음 = 우리 자리.**

---

## 1. 핵심 발견 요약 (5가지)

1. **카메라+마이크 동시 사용 문헌은 극소수.** 베어링 진단에서 스마트폰 카메라+마이크 동시 활용은 **Lu et al. 2016 [1]이 유일**. Meng et al. 2023 [3]은 비전+음향 융합이나 **전용 고속카메라** 기반. Samuelson et al. 2020 [4]은 SHM에서 저주파(비디오)/고주파(마이크) 분할 체계를 제안했으나 **베어링 아님**.
2. **음향-진동 융합 딥러닝은 풍부하나 전부 "가속도계+마이크".** Wang 2020 [5](1D-CNN, 414회), Lin 2024 [6](CCFT, 39회), You 2024 [8](PFCG, 135회) 등 — **영상 모달리티가 포함된 융합은 사실상 없음**.
3. **주파수 역할분담(영상=저주파/음향=고주파)은 Lu 2016 [1]이 이미 구현 — 단 영상은 "결함정보 없는 회전 기준자".** ✅정독 확인: Lu는 영상=회전속도(저주파 기준), 음향=결함주파수(고주파)로 나눴으나 **영상은 결함 판별력이 없고(스칼라 IFR만) 결함은 전적으로 음향에서 규칙기반으로 판정**. → 미개척인 것은 "**영상·음향 양쪽이 결함정보를 담고 딥러닝으로 융합**"하는 체계(우리 자리). Samuelson 2020 [4](SHM)은 서브나이퀴스트 복원 계열로 별개.
4. **스마트폰 슬로모션 영상의 오디오 트랙 활용은 Lu 2016 [1]이 유일.** ✅정독 확인: (a) 영상에서 변위 스펙트럼이 아닌 **회전속도(IFR)만** 추출(프레임 상관계수→STFT→ridge), (b) **FCO=IFCF/IFR 나눗셈**으로 차수 산출 후 이론 오더와 97~103% 대조(규칙 기반), (c) **딥러닝 특징 융합 미사용**, (d) **iPhone 5s 120fps**(240fps는 미래 언급), (e) **3클래스(OR/IR/정상), 볼 결함 없음**.
5. **연구 갭(우리 차별성):** (a) 스마트폰 영상에서 변위 특징(저주파) + (b) 동일 스마트폰 마이크에서 고주파 결함 임펄스 특징 + (c) **딥러닝 기반(early/feature/late) 융합**으로 베어링 분류 — 문헌에 없는 독자 체계.

---

## 2. 논문 분류 (근접도 순)

### 2-1. 영상+음향 멀티모달 (우리와 같은 조합·직접 경쟁) — 단 3편
| 논문 | 카메라 | 융합 방식 | 스마트폰? | 우리와 차이 |
|------|--------|-----------|:--------:|-------------|
| **Lu 2016 [1]** (Math. Prob. Eng., 6회) ✅정독 | **스마트폰(iPhone 5s 120fps)** | 신호처리 FCO=IFCF/IFR (규칙기반 오더대조) | ✅ | 영상=회전속도만(변위X, 결함정보 0), 나눗셈, DL 없음, 3클래스(볼결함 없음) |
| Lu 2016 [2] (IEEE TIM, 57회) | 전용 고속카메라 | KLT 각도추출→음향 각도리샘플링→오더분석 | ✗ | 스마트폰X, DL X, 오더분석 |
| Meng 2023 [3] (IEEE TIM, 40회) | 전용 고속카메라 | phase-based 비전+음향→커널 융합→그래프어텐션 | ✗ | 스마트폰X, 고속카메라, GAT |

### 2-2. 영상+음향 멀티모달 (베어링 아님·SHM)
| 논문 | 내용 |
|------|------|
| Samuelson 2020 [4] (SHM) | 비디오 서브나이퀴스트 진동 복원 + 마이크로 주파수 보정. **"저주파 영상 + 고주파 음향" 개념의 최근접 선례**(단 구조물 SHM) |

### 2-3. 진동+음향 멀티모달 딥러닝 (영상 없음 — 융합 아키텍처 참고용)
| 논문 | 기여 |
|------|------|
| Wang 2020 [5] (Measurement, **414회**) | vibro-acoustic **1D-CNN 융합의 선구**. 융합 벤치마크 |
| You 2024 [8] (RESS, 135회) | **물리정보 융합**(PFCG), 15-DOF 동역학 제약, 99.45%/0.62M |
| Lin 2024 [6] (IEEE/ASME Mechatronics, 39회) | **CCFT** 교차융합 트랜스포머 |
| Wan 2023 [7] (Sensors, 24회) | 가변속도 F-MSCNN, 원시신호 직접 융합 |

### 2-4. 단일모달·음향 (스마트폰 마이크 — 음향 모달리티 근거)
| 논문 | 내용 |
|------|------|
| Rzeszuciński 2018 [11] (IEEE Ind.Appl.Mag., 26회) | **모바일폰 마이크만**으로 베어링 결함. 폰 마이크 <200Hz 한계에도 신호처리로 탐지 |
| Kıranyaz 2024 [12] (IEEE Sensors J., 27회) | **QU-DMBF 벤치마크**(음향+진동 1080조건). **음향이 센서위치 독립적·더 강건** 입증 |
| Devecioğlu 2023 [13] (arXiv) | **Sound-to-Vibration 변환** — 폰 마이크 음향→합성 진동→기존 모델 입력 |

### 2-5. 단일모달·영상 / 기반 기술
| 논문 | 내용 |
|------|------|
| Davis 2014 [9] (ACM TOG, **361회**) | **The Visual Microphone** — 고속영상 미세진동에서 소리 복원. 영상↔음향 관계의 이론적 근간(우리의 역방향) |
| Ambre 2023 [10] (River Publishers) | 스마트폰 영상 진동추출(ODS), **마이크 미융합** |
| Li 2024 [14] (IEEE TII, 170회) | 이벤트 카메라 베어링 진단, 전용 하드웨어 |

---

## 3. 가장 근접한 Lu et al. 2016 [1] vs 우리

| 항목 | Lu 2016 [1] | 우리(제안) |
|------|-------------|-----------|
| 기기 | 스마트폰(카메라+마이크) | 스마트폰(카메라+마이크) — 동일 |
| 영상에서 추출 | **회전속도(IFR)만** | **변위(DisplacementZ) 저주파 특징** |
| 음향에서 추출 | 결함특성주파수(IFCF) | 고주파 결함 임펄스 특징(BPFO/BPFI 포락) |
| 융합 | **FCO = IFCF ÷ IFR** (신호처리 나눗셈) | **딥러닝 융합**(early/feature/late) |
| 출력 | 결함 오더 판정 | 베어링 4클래스(정상/IR/OR/B) 분류 |
| 강건성/평가 | 제한적 | 다조건 + 누수 없는 평가(델타 ①③) |

→ **동일 컨셉의 씨앗은 2016년에 있었으나, 딥러닝·변위스펙트럼·다조건·정직한 평가로 확장한 체계는 없음.** 우리가 그 공백을 채움.

## 4. 우리 D1 실증과의 연결
- 우리는 실제 슬로모션 파일에서 **스마트폰 오디오가 BPFO(외륜 결함)를 담고 있음을 실측 확인**([audio_feasibility_analysis.md]).
- 이는 [1]의 "폰 마이크로 IFCF 추출" 가정을 우리 데이터로 재확인하는 동시에, **포락선 기반 고주파 특징**을 딥러닝 융합에 쓸 수 있음을 시사.
- 즉 문헌 갭(3,4,5) + 우리 실측 = **"스마트폰 영상-음향 딥러닝 융합 베어링 진단"의 실현 가능성과 신규성 동시 확보.**

## 5. 논문 프레이밍 함의
- **novelty 주장 강화**: "카메라+마이크 융합"은 극소수(3편), "스마트폰"은 1편([1]), "저주파영상+고주파음향 딥러닝 융합 베어링 분류"는 **0편**.
- **선행 계보 인용 전략**: [1] Lu(직접 선례·차별화 대상) / [4] Samuelson(주파수분할 개념) / [5][8] Wang·You(음향-진동 DL 융합 아키텍처 차용) / [9] Davis(영상-음향 이론근간) / [12] Kıranyaz(음향 강건성 근거).
- **주의**: [8] You의 physics-informed 융합, [6] Lin의 cross-fusion transformer는 **우리 융합 아키텍처 설계에 직접 참고** 가능.

## 6. 다음 단계
- [ ] 원문 확보 우선순위: **[1] Lu 2016(필수), [3] Meng 2023, [4] Samuelson 2020, [5] Wang 2020, [8] You 2024.** → `papers/`.
- [ ] 정상/IR/B 오디오 분석으로 클래스별 분별성 확인 → 음향 단독 vs 영상 vs 융합 ablation 설계.
- [ ] 융합 아키텍처 후보 결정(early/feature/late; [5][6][8] 참고).

---

## 참고문헌
[1] S. Lu, X. Wang, F. Liu, Q. He, Y. Liu, J. Zhao, "Fault Diagnosis of Motor Bearing by Analyzing a Video Clip," *Mathematical Problems in Engineering*, 2016. (6회) hindawi.com/journals/mpe/2016/8139273/
[2] S. Lu, J. Guo, Q. He, F. Liu, Y. Liu, J. Zhao, "A Novel Contactless Angular Resampling Method for Motor Bearing Fault Diagnosis Under Variable Speed," *IEEE Trans. Instrum. Meas.*, 2016. (57회)
[3] Z. Meng, J. Zhu, S. Cao, P. Li, C. Xu, "Bearing Fault Diagnosis Under Multisensor Fusion Based on Modal Analysis and Graph Attention Network," *IEEE Trans. Instrum. Meas.*, 2023. (40회)
[4] C. R. Samuelson, C. A. Duffy-Deno, C. B. Whitworth, D. Mascareñas, J. D. Tippmann, A. Cattaneo, "Visio-Acoustic Data Fusion for Structural Health Monitoring Applications," River Publishers, 2020. (1회)
[5] X. Wang, D. Mao, X. Li, "Bearing fault diagnosis based on vibro-acoustic data fusion and 1D-CNN network," *Measurement*, 2020. (**414회**)
[6] T. Lin, Y. Zhu, Z. Ren, K. Huang, D. Gao, "CCFT: The Convolution and Cross-Fusion Transformer for Fault Diagnosis of Bearings," *IEEE/ASME Trans. Mechatronics*, 2024. (39회)
[7] H. Wan, X. Gu, S. Yang, Y. Fu, "A Sound and Vibration Fusion Method for Fault Diagnosis of Rolling Bearings under Speed-Varying Conditions," *Sensors*, 2023. (24회)
[8] K. You, P. Wang, H. Peng, Y. Gu, "A sound-vibration physical-information fusion constraint-guided deep learning method for rolling bearing fault diagnosis," *Reliability Engineering & System Safety*, 2024. (135회)
[9] A. Davis, M. Rubinstein, N. Wadhwa, G. J. Mysore, F. Durand, W. T. Freeman, "The Visual Microphone," *ACM Trans. Graph.*, 2014. (**361회**)
[10] D. Ambre, B. Schwarz, S. Richardson, M. Richardson, "Using Cell Phone Videos to Diagnose Machinery Faults," River Publishers, 2023. (1회)
[11] P. Rzeszuciński, M. Orman, C. T. Pinto, A. Tkaczyk, M. Sułowicz, "Bearing Health Diagnosed with a Mobile Phone: Acoustic Signal Measurements...," *IEEE Industry Applications Magazine*, 2018. (26회)
[12] S. Kıranyaz, Ö. C. Devecioğlu, A. Alhams, S. Sassi, T. İnce, O. Avcı, M. Gabbouj, "Exploring Sound Versus Vibration for Robust Fault Detection on Rotating Machinery," *IEEE Sensors Journal*, 2024. (27회)
[13] Ö. C. Devecioğlu et al., "Sound-to-Vibration Transformation for Sensorless Motor Health Monitoring," arXiv:2305.07960, 2023. (2회)
[14] X. Li, S. Yu, Y. Lei, N. Li, B. Yang, "Intelligent Machinery Fault Diagnosis With Event-Based Camera," *IEEE Trans. Industrial Informatics*, 2024. (170회)

> 원본: `papers/multimodal_paper_list.csv` (라이너 스콜라, 16편, 초록·URL 포함).
