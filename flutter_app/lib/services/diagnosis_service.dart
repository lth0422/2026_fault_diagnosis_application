import '../models/diagnosis_result.dart';

/// 결함 진단 서비스.
///
/// ⚠️ 실제 모델 추론은 향후 마일스톤에서 네이티브로 구현한다.
/// 1차 마일스톤에서는 [mockResult] 로 생성한 예시 확률만 사용한다.
/// 클래스 순서는 항상 B, H, IR, OR 을 따른다.
class DiagnosisService {
  /// 실제 진단(모델 추론) (미구현).
  ///
  /// TODO(마일스톤 3): 네이티브 모델 추론 연동.
  /// 모델 입력: DisplacementZ (길이 2048, 형상 [1, 1, 2048]).
  Future<DiagnosisResult> diagnose(List<double> displacementZ) {
    throw UnimplementedError('실제 모델 추론은 아직 구현되지 않았습니다. (마일스톤 3 예정)');
  }

  /// 데모/화면 확인용 mock 진단 결과(B, H, IR, OR 확률).
  DiagnosisResult mockResult() {
    return const DiagnosisResult(
      classLabels: ['B', 'H', 'IR', 'OR'],
      probabilities: [0.08, 0.12, 0.70, 0.10],
    );
  }
}
