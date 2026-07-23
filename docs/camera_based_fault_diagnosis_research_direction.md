# 스마트폰 카메라 기반 회전기계 결함 진단 연구 발전 방향

작성일: 2026-07-23

## 1. 문서 목적

본 문서는 기존 논문 「스마트폰 카메라를 활용한 비접촉식 지능형 회전기계 결함 진단 시스템」과 현재 구현된 Flutter Android/iOS 앱을 기반으로 후속 논문의 연구 문제, 기존 방식의 한계, 현재 시스템의 한계, 검증 실험 방향을 정리한 1차 문헌조사 초안이다.

핵심 방향은 단순히 "스마트폰 앱을 구현했다"는 데 있지 않다. 기존 연구에서 충분히 검증되지 않은 데이터 누수 가능성, 운전 조건 변화, 스마트폰 기종 차이, 카메라 위치와 조명 변화, 마커 의존성, 진단 신뢰성 문제를 체계적으로 검증하고 개선하는 것이 후속 논문의 중심이 되어야 한다.

## 2. 기존 논문의 핵심 내용

### 2.1 제안 시스템

- 스마트폰 초고속 카메라로 회전기계 베어링 하우징을 촬영한다.
- 대상 표면에 부착한 색상 마커를 ROI와 HSV 기반으로 분리한다.
- 마커 중심 좌표를 추적해 픽셀 단위 변위 시계열을 만든다.
- 변위 시계열 2,048개를 WDCNN에 입력한다.
- 정상(H), 볼 결함(B), 내륜 결함(IR), 외륜 결함(OR)을 분류한다.
- 최종 모델을 Android 애플리케이션에 내장한다.

### 2.2 기존 실험 조건

| 항목 | 기존 논문 조건 |
|---|---|
| 촬영 기기 | iPhone 12 Pro |
| 촬영 설정 | 1920 x 1080, 240 fps 슬로 모션 |
| 회전속도 | 1,200 RPM |
| 조명 | 깜빡임이 없는 지속광 |
| 기준 센서 | 16 kHz 가속도 센서 |
| 클래스 | B, H, IR, OR |
| 입력 길이 | 2,048 |
| 데이터 증강 | 슬라이딩 윈도우, 창 2,048, 중첩 1,024 |
| 표본 수 | 1,060개 |
| 평가 | 10-fold 교차검증 |
| WDCNN 정확도 | 99.7 +/- 0.3% |

영상 변위와 가속도 신호의 FFT에서 모두 20 Hz 피크가 관찰되어, 영상 변위가 회전 주파수 성분을 반영할 수 있음을 확인했다.

### 2.3 기존 논문이 제시한 후속 과제

- 마커 없이 특징점을 추적하는 변위 추출 알고리즘 개발.
- 다양한 운전 조건과 외부 노이즈 환경에 강건한 모델 연구.

이 두 항목은 현재도 유효하다. 다만 후속 논문에서는 데이터 분할 방식, 기기 간 차이, 측정 불확도, 신뢰도 보정까지 범위를 넓힐 필요가 있다.

## 3. 카메라 기반 비접촉 진단의 장점

### 3.1 접촉식 센서 대비 장점

- 센서 부착에 따른 질량 부가 효과가 없다.
- 배선과 센서 설치가 곤란한 장비에 적용할 수 있다.
- 하나의 영상에서 여러 지점의 변위를 동시에 얻을 수 있다.
- 스마트폰을 이용하면 산업용 고속 카메라나 레이저 진동계보다 휴대성과 접근성이 높다.
- 영상 저장, 전처리, 추론, 결과 공유를 하나의 모바일 장치에서 수행할 수 있다.

### 3.2 현재 시스템의 실용적 장점

- Android와 iOS에서 같은 Flutter 흐름을 제공한다.
- OpenCV 기반 ROI, HSV, 마커 추적을 온디바이스에서 수행한다.
- 변위 CSV와 추적 품질 지표를 저장하고 공유할 수 있다.
- 네트워크 연결 없이 내장 PyTorch Lite 모델로 진단한다.
- HSV 검출 미리보기, 검출 성공/실패 프레임 수, Z 표준편차, logits를 확인할 수 있다.

## 4. 기존 스마트폰 및 카메라 기반 방식의 공통 한계

### 4.1 시간 해상도와 주파수 대역 제한

일반적인 프레임 기반 진동 계측은 프레임률의 절반보다 높은 주파수에서 앨리어싱 위험이 있다. 240 fps 영상의 일반적인 나이퀴스트 주파수는 120 Hz이다. 기존 논문은 20 Hz 회전 주파수의 재현 가능성을 확인했지만, 베어링 결함의 고주파 충격 성분과 고조파를 충분히 보존하는지는 별도 검증이 필요하다.

고속 촬영에서는 해상도, 노출시간, 밝기, 저장 용량 사이의 절충도 발생한다. 노출시간이 길면 모션 블러가 증가하고, 짧게 하면 더 강한 조명이 필요하다.

### 4.2 공간 해상도와 미세 변위 한계

현재 변위는 픽셀 좌표로 계산된다. 촬영 거리 증가, 광각 렌즈, 낮은 해상도, 압축 노이즈는 한 픀이 나타내는 실제 변위를 크게 만든다. 미세 결함의 작은 진폭은 픽셀 양자화와 영상 노이즈에 묻힐 수 있다.

서브픽셀 추적이나 카메라 캘리브레이션 없이 픽셀 변위만 사용하면 mm 단위의 절대 변위 정확도를 제시하기 어렵다.

### 4.3 카메라 자세와 투영 기하

단안 카메라는 기본적으로 영상 평면 내 2차원 운동을 관측한다. 카메라 광축 방향 운동은 영상 크기 변화와 결합되며, 촬영 각도가 바뀌면 동일한 실제 진동도 서로 다른 픽셀 변위로 나타난다.

따라서 다음 변화는 모델 입력 분포를 바꿀 수 있다.

- 카메라와 장비 사이 거리.
- 광축과 진동 방향 사이 각도.
- ROI 크기와 줌 배율.
- 스마트폰 삼각대 높이와 위치.

### 4.4 카메라 자체 흔들림과 센서 특성

카메라 삼각대나 바닥이 함께 진동하면 장비 진동이 아닌 카메라 운동이 변위에 포함된다. 온도에 따른 영상 센서 변화도 정밀 변위 계측 오차를 만들 수 있다는 실험 연구가 있다.

스마트폰 카메라는 대부분 rolling shutter를 사용한다. 행 단위 노출 시차는 빠른 운동에서 형상 왜곡을 만들며, OIS/EIS, 자동초점, 자동노출, 프레임 보간 및 슬로 모션 저장 방식도 기종별 차이를 유발한다. rolling shutter를 의도적으로 계측에 이용하는 연구도 있지만, 현재 시스템은 이를 보정하거나 계측 원리로 활용하지 않는다.

### 4.5 조명과 표면 상태 의존성

HSV 기반 검출은 조명 밝기, 색온도, 그림자, 반사, 플리커에 민감하다. 같은 색의 배경 물체가 ROI에 들어오면 전체 mask의 중심이 실제 마커 중심에서 벗어날 수 있다.

표면 질감이 부족한 대상에서는 markerless optical flow나 특징점 추적도 불안정해질 수 있다. 반대로 마커 방식은 안정적이지만 현장에 마커를 부착해야 한다는 제약이 남는다.

### 4.6 계산량과 실시간성

고해상도 고프레임률 영상은 저장 용량과 연산량이 크다. 현재 앱은 촬영 후 영상을 불러와 처리하는 방식이므로 실시간 상태 감시 시스템과는 구분된다. 장시간 영상, 저사양 기기, 발열 및 배터리 소모에 대한 평가도 필요하다.

### 4.7 실험실과 현장 사이의 도메인 차이

실험실 데이터는 고정된 속도, 하중, 조명, 배경 및 카메라 배치를 유지하기 쉽다. 실제 현장에서는 속도 변화, 복합 결함, 구조 공진, 주변 장비 진동, 오염, 가림, 불균일 조명이 동시에 존재한다. 실험실 정확도가 높더라도 현장 일반화 성능은 별개의 문제다.

## 5. 기존 논문의 평가상 핵심 위험

### 5.1 슬라이딩 윈도우와 데이터 누수 가능성

기존 논문은 길이 2,048, 중첩 1,024의 슬라이딩 윈도우로 1,060개 표본을 만든 뒤 10-fold 교차검증을 수행했다. 그러나 다음 순서가 논문에 명확히 기술되어 있지 않다.

1. 원본 영상 또는 물리적 베어링 단위로 train/test를 먼저 분리했는가.
2. 전체 시계열을 overlapping window로 만든 뒤 window 단위로 무작위 분할했는가.

두 번째 방식이라면 인접 표본이 절반을 공유하므로 거의 같은 파형이 train fold와 test fold에 동시에 들어갈 수 있다. 이 경우 99.7%는 새로운 베어링이나 새로운 촬영 세션에 대한 성능보다 높게 평가될 수 있다.

따라서 후속 연구에서는 다음 그룹 분할이 필요하다.

- 베어링 개체 단위 분할.
- 촬영 세션 또는 날짜 단위 분할.
- 원본 영상 단위 분할 후 window 생성.
- 최종 독립 테스트 세트는 모델 선택과 하이퍼파라미터 조정에 사용하지 않음.

### 5.2 제한된 운전 조건

기존 성능은 1,200 RPM 중심의 단일 운전 조건에서 측정됐다. 모델이 결함의 일반적 특징을 학습했는지, 특정 속도와 시험 장치의 진폭 패턴을 학습했는지 구분하기 어렵다.

### 5.3 표본 수와 독립 개체 수

window 수가 1,060개이더라도 원본 베어링과 원본 촬영 세션 수가 적다면 통계적으로 독립인 표본 수는 훨씬 작다. 후속 논문에서는 window 수뿐 아니라 다음 수를 함께 보고해야 한다.

- 클래스별 물리적 베어링 수.
- 클래스별 원본 영상 수.
- 촬영 날짜와 반복 실험 수.
- 각 train/validation/test split에 포함된 독립 개체 수.

### 5.4 정확도 중심 평가

평균 정확도만으로는 클래스 불균형, 특정 결함의 반복 오분류, 과도한 softmax 확신을 알기 어렵다. confusion matrix, 클래스별 precision/recall, macro F1, balanced accuracy와 신뢰도 보정 지표를 함께 제시해야 한다.

## 6. 현재 Flutter 앱에서 확인되는 연구적 한계

### 6.1 수동 설정 의존성

사용자가 ROI, 마커 색상, HSV 범위, 마커 중심, 추적 박스 크기를 직접 설정한다. 사용자 숙련도에 따라 입력 시계열이 달라질 수 있으므로 작업자 간 재현성 실험이 필요하다.

### 6.2 추적 실패 처리

마커를 찾지 못한 프레임에서는 직전 중심 좌표를 다시 사용한다. 짧은 누락에는 유용하지만, 실패가 연속되면 평탄한 인공 구간이 만들어져 주파수와 진폭 특성이 왜곡될 수 있다. 현재는 검출/실패 프레임 수를 표시하지만, 진단을 차단하는 최소 검출률 기준은 없다.

### 6.3 동일 색상 물체와 mask 중심 문제

현재 알고리즘은 mask 전체의 moments로 중심을 계산한다. ROI 안에 마커와 같은 색의 반사나 물체가 여러 개 있으면 가장 적절한 contour가 아니라 모든 검출 픽셀의 합성 중심을 추적할 수 있다.

개선 후보는 contour 면적, 원형도, 직전 위치와의 거리, 연결 성분 크기를 함께 이용한 후보 선택이다.

### 6.4 픽셀 변위와 물리 단위

CSV의 변위 단위는 px이다. 촬영 거리와 해상도가 달라지면 동일한 실제 변위도 서로 다른 값이 된다. 학습 데이터와 실제 앱 입력 사이에서 px/mm 비율이 달라지면 모델 성능에 직접 영향을 줄 수 있다.

### 6.5 입력 길이와 시간축 처리

현재 Android와 iOS 구현은 최대 첫 2,048프레임을 사용하고, 길이가 다르면 선형 보간으로 2,048개에 맞춘다. 이 과정은 영상 길이가 다른 경우 시간축과 주파수축을 변화시킬 수 있다. FPS를 사용자가 잘못 입력해도 모델 입력 자체에는 직접 반영되지 않고 CSV 시간축만 잘못 기록될 수 있다.

후속 연구에서는 실제 영상 metadata에서 FPS를 읽고, 초 단위의 고정 구간 또는 회전수 동기화 구간으로 입력을 구성하는 방법을 검토해야 한다.

### 6.6 제한된 진단 클래스와 강제 분류

현재 모델은 모든 입력을 B, H, IR, OR 중 하나로 분류한다. 다음 입력에 대한 거부 기능이 없다.

- 마커 추적 품질이 낮은 영상.
- 학습에 없던 복합 결함.
- 불평형, 축정렬 불량, 느슨함 등 다른 고장.
- 정지 영상 또는 극단적으로 낮은 변위.
- 학습 범위를 벗어난 속도와 기기.

따라서 높은 softmax 확률을 진단 정확도와 동일하게 해석하면 안 된다. 입력 품질 판정과 out-of-distribution 또는 unknown 판정이 필요하다.

### 6.7 플랫폼 간 결과 차이

현재 문서에는 동일 계열 IR 영상이 iOS에서 OR로 분류된 사례가 기록되어 있다. 프레임 디코딩, 회전 metadata, 색공간, ROI 좌표 복원, OpenCV 버전 및 부동소수점 차이가 원인일 수 있다. 동일 영상과 동일 CSV를 사용한 단계별 비교가 필요하다.

### 6.8 학습 전처리 계약 미확인

현재 앱은 Y 좌표 평균을 제거한 px 변위를 모델에 바로 입력한다. 학습 당시 사용한 평균 제거, 정규화, 필터링, 보간 방법과 완전히 동일한지는 학습 코드를 통해 재검증해야 한다.

## 7. 후속 논문의 권장 연구 질문

### RQ1. 독립 베어링과 독립 촬영 세션에서도 높은 진단 성능이 유지되는가?

가장 먼저 검증해야 할 질문이다. 기존 99.7%를 leakage-free split으로 재평가한다.

### RQ2. 스마트폰 기종, 운영체제, 촬영 위치가 달라도 진단이 가능한가?

Android와 iOS, 카메라 거리와 각도, 조명 조건을 domain으로 정의하고 교차 조건 성능을 측정한다.

### RQ3. 영상 변위의 측정 정확도는 기준 센서와 어느 정도 일치하는가?

동기화된 가속도 센서 또는 레이저 변위계와 비교해 주파수 피크 오차, 변위 진폭 오차, 파형 상관계수를 측정한다.

### RQ4. 마커 기반 방식과 markerless 방식의 정확도 및 사용성 차이는 무엇인가?

현재 HSV 마커 추적을 기준선으로 두고 optical flow, phase-based method, 특징점 추적 방법을 비교한다.

### RQ5. 모델이 잘못된 입력을 스스로 거부할 수 있는가?

검출률, Z 표준편차, 주파수 품질, softmax entropy 또는 calibration을 결합한 품질 판정기를 제안한다.

## 8. 권장 실험 설계

### 8.1 1단계: 기존 정확도 재검증

- 원본 영상 ID와 물리적 베어링 ID를 정리한다.
- overlapping window 생성 전 train/validation/test를 분리한다.
- leave-one-bearing-out 또는 GroupKFold를 적용한다.
- 기존 random window split 결과와 group split 결과를 함께 제시한다.
- WDCNN, ANN, 간단한 1D CNN을 동일 split에서 비교한다.

이 실험만으로도 기존 99.7%의 의미를 명확히 할 수 있으며, 후속 논문의 필수 기반이 된다.

### 8.2 2단계: 카메라 계측 정확도 검증

| 평가 항목 | 권장 지표 |
|---|---|
| 주파수 재현 | 주요 피크 주파수 절대/상대 오차 |
| 파형 유사도 | Pearson correlation, coherence |
| 진폭 재현 | RMSE, NRMSE, 진폭 비율 |
| 추적 품질 | 검출률, 연속 실패 길이, 중심점 jitter |
| 반복성 | 동일 조건 반복 측정의 표준편차 |

가속도 신호와 영상 변위는 물리량이 다르므로 단순 진폭 비교만 하지 말고, 주파수 성분과 coherence를 함께 평가해야 한다.

### 8.3 3단계: 조건 변화 일반화

권장 최소 변수는 다음과 같다.

| 변수 | 예시 수준 |
|---|---|
| 스마트폰 | iPhone 12 Pro, iPhone 12 mini, Galaxy S23 |
| 회전속도 | 저속, 학습 속도 1,200 RPM, 고속 |
| 촬영 거리 | 근거리, 기준 거리, 원거리 |
| 촬영 각도 | 정면, 좌우 또는 상하 경사 |
| 조명 | 지속광, 일반 실내등, 저조도 |
| 배경 | 단순 배경, 유사 색상 물체 포함 |
| 마커 | 기준 마커, 크기 변화, markerless |

모든 조합을 전부 수행하기 어렵다면 직교배열이나 주요 영향 인자 중심의 부분 요인 실험을 사용할 수 있다.

### 8.4 4단계: 현장성 및 사용성

- 초보 사용자와 숙련 사용자의 ROI/HSV 설정 결과 비교.
- 전체 진단 소요시간, 실패율, 재시도 횟수 측정.
- Android와 iOS에서 동일 영상의 CSV와 logits 비교.
- 장시간 처리 시 발열, 메모리, 배터리 사용량 측정.
- 잘못된 ROI, 낮은 검출률, 학습 외 결함에 대한 거부 성능 평가.

## 9. 논문 기여로 만들기 좋은 개선 방향

### 우선순위 1. Leakage-free 일반화 검증

새로운 모델을 만드는 것보다 먼저 필요하다. 물리적 베어링과 촬영 세션을 완전히 분리한 평가만으로 연구의 신뢰도가 크게 향상된다.

### 우선순위 2. 자동 품질 판정 및 진단 거부

현재 앱이 이미 제공하는 검출률, 실패 프레임 수, Z 표준편차, logits를 활용할 수 있다. 품질이 낮으면 결함명을 강제로 출력하지 않고 재촬영 또는 재설정을 요구하는 구조가 실용성과 안전성을 높인다.

### 우선순위 3. 기종 및 조건 불변 전처리

- px 변위를 기준 크기 또는 마커 지름으로 정규화.
- FPS metadata 자동 추출.
- 회전속도 기반 order tracking 또는 회전수 동기화 리샘플링.
- 카메라 흔들림 보정을 위한 고정 배경점 또는 스마트폰 IMU 결합.
- 자동 노출/초점 고정과 촬영 품질 검사.

### 우선순위 4. 반자동 또는 markerless 추적

완전 markerless가 불안정하다면 다음과 같은 단계적 접근이 현실적이다.

1. 마커 자동 검출과 HSV 자동 초기화.
2. contour 기반 마커 후보 선택.
3. 마커가 잠시 사라질 때 optical flow 또는 Kalman filter로 보완.
4. 충분한 질감이 있는 대상에서 markerless 특징점 추적 비교.

## 10. 후속 논문의 권장 핵심 주장

후속 논문의 가장 설득력 있는 방향은 다음과 같다.

> 본 연구는 스마트폰 카메라 기반 회전기계 결함 진단을 Android와 iOS 온디바이스 시스템으로 구현하고, 물리적 베어링 및 촬영 세션 단위로 분리된 누수 방지 평가를 수행한다. 또한 스마트폰 기종, 카메라 위치, 조명 및 회전속도 변화에 따른 영상 변위와 진단 성능을 정량화하고, 추적 품질 기반 진단 거부 메커니즘을 도입해 현장 적용 신뢰성을 향상한다.

이 주장은 단순 앱 이전보다 연구적 기여가 분명하고, 기존 논문에서 제시한 다양한 조건과 강건성 문제를 직접 확장한다.

## 11. 우선 검토할 관련 논문

### 영상 기반 진동 및 회전기계 진단

1. Cong Peng, Haining Gao, Xiaoyue Liu, Bin Liu, "A visual vibration characterization method for intelligent fault diagnosis of rotating machinery," Mechanical Systems and Signal Processing, 2023. [DOI](https://doi.org/10.1016/j.ymssp.2023.110229)
   - 산업용 고속 카메라의 영상 위상 정보를 이용한 회전기계 결함 진단 사례.

2. Giulio D'Emilia, Laura Razze, Emanuele Zappa, "Uncertainty analysis of high frequency image-based vibration measurements," Measurement, 2013. [DOI](https://doi.org/10.1016/j.measurement.2013.04.075)
   - 카메라 주파수 범위와 진폭 측정 불확도를 실험적으로 분석.

3. "A fast high-resolution vibration measurement method based on vision technology for structures," Nuclear Engineering and Technology, 2021. [DOI](https://doi.org/10.1016/j.net.2020.06.019)
   - 카메라 하드웨어 해상도와 대규모 영상 처리의 한계를 설명.

4. "Vibration displacement measurement method based on vision Gaussian fitting and edge optimisation for rotating shafts," Measurement, 2024. [DOI](https://doi.org/10.1016/j.measurement.2024.114699)
   - 회전축의 미세 변위를 위한 서브픽셀급 edge 기반 접근.

5. "Vision-based bearing fault diagnosis under non-stationary conditions using optimized short-time concentrated transform method," Reliability Engineering & System Safety, 2025. [DOI](https://doi.org/10.1016/j.ress.2025.111183)
   - 가변속 조건에서 optical flow와 시간-주파수 분석을 결합한 베어링 진단.

### 스마트폰 카메라와 보정

6. "A smartphone camera and built-in gyroscope based application for non-contact yet accurate off-axis structural displacement measurements," Measurement, 2021. [DOI](https://doi.org/10.1016/j.measurement.2020.108449)
   - 스마트폰 카메라와 gyroscope를 결합해 비정면 촬영을 보정.

7. "Rotating machinery speed extraction through smartphone video acquisition from a radial viewpoint," Mechanical Systems and Signal Processing, 2023. [DOI](https://doi.org/10.1016/j.ymssp.2023.110836)
   - 스마트폰 rolling shutter를 활용한 회전속도 추출과 오차 분석.

8. Lei Xing, Wujiao Dai, Yunsheng Zhang, "Improving displacement measurement accuracy by compensating for camera motion and thermal effect on camera sensor," Mechanical Systems and Signal Processing, 2022. [DOI](https://doi.org/10.1016/j.ymssp.2021.108525)
   - 카메라 운동과 센서 온도 변화가 만드는 측정 오차를 다룸.

9. "Multi-sensor fusion for structural displacement estimation: Integrating vision and acceleration from mobile devices," Engineering Structures, 2025. [DOI](https://doi.org/10.1016/j.engstruct.2025.119826)
   - 모바일 카메라와 내장 관성 센서를 결합해 조명과 카메라 운동에 대한 강건성을 개선.

### 모델과 평가 방법

10. Wei Zhang et al., "A New Deep Learning Model for Fault Diagnosis with Good Anti-Noise and Domain Adaptation Ability on Raw Vibration Signals," Sensors, 2017. [DOI](https://doi.org/10.3390/s17020425)
    - 기존 논문에서 사용한 WDCNN 구조의 기반 연구.

11. Joao Paulo Vieira et al., "Towards a more realistic evaluation of machine learning models for bearing fault diagnosis," Mechanical Systems and Signal Processing, 2026 온라인 선공개. [DOI](https://doi.org/10.1016/j.ymssp.2026.114640)
    - window 단위 분할의 데이터 누수 문제와 bearing-wise 분할 필요성을 직접 다룸.

12. Hiroyuki Kayaba, Yuji Kokumai, "Non-Contact Full Field Vibration Measurement Based on Phase-Shifting," CVPR, 2017. [논문 페이지](https://openaccess.thecvf.com/content_cvpr_2017/html/Kayaba_Non-Contact_Full_Field_CVPR_2017_paper.html)
    - 마커 없이 full-field 진동을 측정하는 대안적 접근.

## 12. 바로 수행할 다음 작업

1. 기존 학습 코드와 원본 데이터의 위치를 확보한다.
2. 원본 영상, 베어링 ID, 촬영 세션 ID, 결함 라벨을 하나의 manifest로 정리한다.
3. 기존 10-fold 분할이 window 단위인지 원본 영상/베어링 단위인지 확인한다.
4. 기존 WDCNN을 leakage-free split으로 다시 학습하고 정확도 차이를 측정한다.
5. 동일 영상에 대해 Android/iOS가 생성한 CSV와 logits를 비교한다.
6. 가속도 센서와 스마트폰 영상을 동기화하는 신규 데이터 수집 계획을 작성한다.

가장 중요한 첫 단계는 새로운 모델 개발이 아니라 기존 데이터 분할과 학습 전처리의 재현이다. 이 결과에 따라 후속 논문의 주제가 모델 개선, 영상 계측 개선, 일반화 검증 중 어디에 가장 무게를 둘지 결정할 수 있다.
