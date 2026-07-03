/// 마커 추적으로부터 계산된 변위(Displacement) 결과를 표현하는 모델.
///
/// 진단 모델의 입력은 DisplacementZ 시계열이며, 목표 길이는 2048 이다.
/// (모델 입력 형상: [1, 1, 2048])
/// 1차 마일스톤에서는 mock 데이터로만 채워진다.
class DisplacementResult {
  /// DisplacementZ 시계열 데이터. 모델 입력 목표 길이는 2048.
  final List<double> displacementZ;

  const DisplacementResult({this.displacementZ = const []});

  int get length => displacementZ.length;

  bool get isEmpty => displacementZ.isEmpty;

  double get minValue =>
      displacementZ.isEmpty ? 0 : displacementZ.reduce((a, b) => a < b ? a : b);

  double get maxValue =>
      displacementZ.isEmpty ? 0 : displacementZ.reduce((a, b) => a > b ? a : b);

  @override
  String toString() =>
      'DisplacementResult(length: $length, min: $minValue, max: $maxValue)';
}
