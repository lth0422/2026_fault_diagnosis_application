import '../models/displacement_result.dart';

/// [향후 마일스톤용 스텁] 네이티브 변위 추출 연동을 위한 채널 래퍼.
///
/// 실제 변위 추출은 iOS/Android 네이티브(OpenCV 등)에서 수행할 예정이며,
/// 그 구현은 각각 `ios/`, `android/` 플랫폼 폴더에 위치한다.
///
/// ⚠️ 1차 마일스톤에서는 네이티브 MethodChannel 을 구현하지 않으므로,
/// 이 클래스는 채널 이름만 정의한 스텁 상태이다. (MethodChannel 미연결)
class NativeDisplacementChannel {
  /// 네이티브 측과 공유할 채널 이름(향후 사용).
  static const String channelName = 'fault_diagnosis/displacement';

  /// 영상으로부터 DisplacementZ 시계열을 추출한다.
  ///
  /// TODO(마일스톤 2): iOS/Android 네이티브 변위 추출 구현 후 연결.
  Future<DisplacementResult> extractDisplacement(String videoPath) {
    throw UnimplementedError(
      '네이티브 변위 추출은 아직 구현되지 않았습니다. (마일스톤 2 예정)',
    );
  }
}
