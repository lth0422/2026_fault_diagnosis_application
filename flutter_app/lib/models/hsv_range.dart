/// 마커 검출에 사용할 HSV 색공간 범위를 표현하는 모델.
///
/// 기본값은 레거시 Android 앱의 프리셋 범위(H: 0~180, S/V: 0~255)를 따른다.
/// 1차 마일스톤에서는 실제 HSV 필터링을 수행하지 않는다.
class HsvRange {
  final double hMin;
  final double hMax;
  final double sMin;
  final double sMax;
  final double vMin;
  final double vMax;

  const HsvRange({
    this.hMin = 0,
    this.hMax = 180,
    this.sMin = 0,
    this.sMax = 255,
    this.vMin = 0,
    this.vMax = 255,
  });

  HsvRange copyWith({
    double? hMin,
    double? hMax,
    double? sMin,
    double? sMax,
    double? vMin,
    double? vMax,
  }) {
    return HsvRange(
      hMin: hMin ?? this.hMin,
      hMax: hMax ?? this.hMax,
      sMin: sMin ?? this.sMin,
      sMax: sMax ?? this.sMax,
      vMin: vMin ?? this.vMin,
      vMax: vMax ?? this.vMax,
    );
  }

  @override
  String toString() =>
      'HsvRange(H: $hMin-$hMax, S: $sMin-$sMax, V: $vMin-$vMax)';
}
