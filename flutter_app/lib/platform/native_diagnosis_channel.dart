import '../models/diagnosis_result.dart';

/// [향후 마일스톤용 스텁] 네이티브 진단 모델 추론 연동을 위한 채널 래퍼.
///
/// 실제 추론은 네이티브에서 수행할 예정이며, 그 구현은 각각 `ios/`, `android/`
/// 플랫폼 폴더에 위치한다.
/// (참조 Android 구현은 PyTorch Mobile Lite 모델 `Fwdcnn7.ptl` 사용 → logits 에
///  softmax 적용. iOS 는 이후 대응 방식 결정 예정.)
///
/// 모델 입력: DisplacementZ (길이 2048, 형상 [1, 1, 2048])
/// 클래스 순서: B, H, IR, OR
///
/// ⚠️ 1차 마일스톤에서는 네이티브 MethodChannel 을 구현하지 않으므로,
/// 이 클래스는 채널 이름만 정의한 스텁 상태이다. (MethodChannel 미연결)
class NativeDiagnosisChannel {
  /// 네이티브 측과 공유할 채널 이름(향후 사용).
  static const String channelName = 'fault_diagnosis/diagnosis';

  /// DisplacementZ 시계열을 입력받아 결함 진단을 수행한다.
  ///
  /// TODO(마일스톤 3): iOS/Android 네이티브 모델 추론 구현 후 연결.
  Future<DiagnosisResult> diagnose(List<double> displacementZ) {
    throw UnimplementedError(
      '네이티브 모델 추론은 아직 구현되지 않았습니다. (마일스톤 3 예정)',
    );
  }
}
