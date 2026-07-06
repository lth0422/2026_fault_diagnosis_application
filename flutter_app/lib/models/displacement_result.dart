/// 마커 추적으로부터 계산된 변위(Displacement) 결과를 표현하는 모델.
///
/// 진단 모델의 입력은 DisplacementZ 시계열이며, 목표 길이는 2048 이다.
/// (모델 입력 형상: [1, 1, 2048])
/// Android에서는 OpenCV 네이티브 처리 결과로 채워진다.
class DisplacementResult {
  /// DisplacementZ 시계열 데이터. 모델 입력 목표 길이는 2048.
  final List<double> displacementZ;

  /// Android에 저장된 CSV의 content URI 또는 파일 URI.
  final String? csvUri;

  /// 사용자가 찾기 쉬운 CSV 저장 위치/파일명.
  final String? csvDisplayName;

  /// 실제 추적에 사용된 원본 프레임 수.
  final int rawLength;

  /// HSV mask moments로 마커를 찾은 프레임 수.
  final int detectedFrameCount;

  /// 마커를 찾지 못해 이전 위치를 재사용한 프레임 수.
  final int missedFrameCount;

  /// DisplacementZ 표준편차. 0에 가까우면 추적이 거의 움직이지 않았다는 신호다.
  final double zStdDev;

  const DisplacementResult({
    this.displacementZ = const [],
    this.csvUri,
    this.csvDisplayName,
    this.rawLength = 0,
    this.detectedFrameCount = 0,
    this.missedFrameCount = 0,
    this.zStdDev = 0,
  });

  int get length => displacementZ.length;

  bool get isEmpty => displacementZ.isEmpty;

  double get minValue =>
      displacementZ.isEmpty ? 0 : displacementZ.reduce((a, b) => a < b ? a : b);

  double get maxValue =>
      displacementZ.isEmpty ? 0 : displacementZ.reduce((a, b) => a > b ? a : b);

  @override
  String toString() =>
      'DisplacementResult(length: $length, min: $minValue, max: $maxValue, std: $zStdDev, detected: $detectedFrameCount, missed: $missedFrameCount, csv: $csvDisplayName)';
}
