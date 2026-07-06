import 'dart:ui' show Offset;

/// 변위 추적 대상이 되는 색상 마커 정보를 표현하는 모델.
///
/// 1차 마일스톤에서는 마커 검출을 수행하지 않으므로 [center]는 null 일 수 있다.
class MarkerInfo {
  /// 마커 식별자.
  final int id;

  /// 마커 대표 색상(ARGB 32비트 값).
  final int colorValue;

  /// 검출된 마커 중심 좌표(미검출 시 null).
  ///
  /// 현재 Flutter 구현에서는 ROI로 잘린 첫 프레임 기준의 픽셀 좌표로 저장한다.
  final Offset? center;

  /// 마커 추적에 사용할 중심 주변 박스 크기(px).
  final double trackingBoxSize;

  const MarkerInfo({
    required this.id,
    this.colorValue = 0xFFFF0000,
    this.center,
    this.trackingBoxSize = 80,
  });

  bool get isDetected => center != null;

  MarkerInfo copyWith({
    int? id,
    int? colorValue,
    Offset? center,
    double? trackingBoxSize,
  }) {
    return MarkerInfo(
      id: id ?? this.id,
      colorValue: colorValue ?? this.colorValue,
      center: center ?? this.center,
      trackingBoxSize: trackingBoxSize ?? this.trackingBoxSize,
    );
  }

  @override
  String toString() =>
      'MarkerInfo(id: $id, color: 0x${colorValue.toRadixString(16)}, center: $center, box: $trackingBoxSize)';
}
