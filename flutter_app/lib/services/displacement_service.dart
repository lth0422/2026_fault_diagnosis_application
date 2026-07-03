import 'dart:math' as math;

import '../models/displacement_result.dart';

/// 변위(DisplacementZ) 계산 서비스.
///
/// ⚠️ 실제 계산(마커 추적 기반)은 향후 마일스톤에서 네이티브로 구현한다.
/// 1차 마일스톤에서는 [mockResult] 로 생성한 예시 데이터만 사용한다.
class DisplacementService {
  /// 실제 변위 계산 (미구현).
  ///
  /// TODO(마일스톤 2): 네이티브 변위 추출 연동.
  Future<DisplacementResult> computeDisplacement(String videoPath) {
    throw UnimplementedError('실제 변위 계산은 아직 구현되지 않았습니다. (마일스톤 2 예정)');
  }

  /// 데모/화면 확인용 mock DisplacementZ 시계열(길이 2048)을 생성한다.
  ///
  /// 모델 입력 목표 길이(2048)에 맞춘 사인파 + 약간의 노이즈.
  DisplacementResult mockResult({int length = 2048}) {
    final rng = math.Random(42);
    final data = List<double>.generate(length, (i) {
      final base = math.sin(i / 32.0) * 1.5;
      final noise = (rng.nextDouble() - 0.5) * 0.3;
      return base + noise;
    });
    return DisplacementResult(displacementZ: data);
  }
}
