/// 관심 영역(Region Of Interest) 정보를 표현하는 모델.
///
/// 좌표/크기는 0.0 ~ 1.0 정규화 값으로 저장한다(프레임 크기에 독립적).
/// 실제 픽셀 좌표 변환은 영상 처리 단계(향후 마일스톤)에서 수행한다.
class RoiInfo {
  final double x;
  final double y;
  final double width;
  final double height;

  const RoiInfo({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
  });

  bool get isEmpty => width <= 0 || height <= 0;

  RoiInfo copyWith({double? x, double? y, double? width, double? height}) {
    return RoiInfo(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  String toString() => 'RoiInfo(x: $x, y: $y, w: $width, h: $height)';
}
