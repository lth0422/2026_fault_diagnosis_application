/// 결함 진단 모델의 출력을 표현하는 모델.
///
/// 클래스 순서는 반드시 **B, H, IR, OR** 를 따른다.
/// Android에서는 내장 PyTorch Lite 모델의 softmax 확률로 채워진다.
class DiagnosisResult {
  /// 클래스 레이블. 기본 순서: B, H, IR, OR.
  final List<String> classLabels;

  /// 각 클래스에 대한 확률(0.0 ~ 1.0). [classLabels]와 인덱스가 일치한다.
  final List<double> probabilities;

  /// softmax 전 모델 원본 출력값.
  final List<double> logits;

  const DiagnosisResult({
    this.classLabels = const ['B', 'H', 'IR', 'OR'],
    this.probabilities = const [0, 0, 0, 0],
    this.logits = const [],
  });

  /// 가장 확률이 높은 클래스의 인덱스.
  int get predictedIndex {
    if (probabilities.isEmpty) return -1;
    var best = 0;
    for (var i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[best]) best = i;
    }
    return best;
  }

  /// 예측된 클래스 레이블.
  String get predictedLabel {
    final i = predictedIndex;
    return (i < 0 || i >= classLabels.length) ? '-' : classLabels[i];
  }

  /// 예측된 클래스의 확률(신뢰도).
  double get confidence {
    final i = predictedIndex;
    return (i < 0 || i >= probabilities.length) ? 0 : probabilities[i];
  }

  @override
  String toString() =>
      'DiagnosisResult(predicted: $predictedLabel, confidence: $confidence)';
}
