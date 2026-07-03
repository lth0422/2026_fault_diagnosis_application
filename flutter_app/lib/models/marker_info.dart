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
  final Offset? center;

  const MarkerInfo({
    required this.id,
    this.colorValue = 0xFFFF0000,
    this.center,
  });

  bool get isDetected => center != null;

  MarkerInfo copyWith({int? id, int? colorValue, Offset? center}) {
    return MarkerInfo(
      id: id ?? this.id,
      colorValue: colorValue ?? this.colorValue,
      center: center ?? this.center,
    );
  }

  @override
  String toString() =>
      'MarkerInfo(id: $id, color: 0x${colorValue.toRadixString(16)}, center: $center)';
}
