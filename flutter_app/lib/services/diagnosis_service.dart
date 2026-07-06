import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/diagnosis_result.dart';

/// 결함 진단 서비스.
///
/// Android에서는 PyTorch Mobile Lite 모델(`Fwdcnn7.ptl`)을 네이티브 채널로 실행한다.
/// iOS 구현 전까지 비 Android 환경에서는 [mockResult]를 fallback으로 사용한다.
/// 클래스 순서는 항상 B, H, IR, OR 을 따른다.
class DiagnosisService {
  static const MethodChannel _channel = MethodChannel('fault_diagnosis/model');

  /// 모델 입력: DisplacementZ (길이 2048, 형상 [1, 1, 2048]).
  Future<DiagnosisResult> diagnose(List<double> displacementZ) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return mockResult();
    }
    if (displacementZ.length != 2048) {
      throw StateError('모델 입력 길이는 2048이어야 합니다. 현재: ${displacementZ.length}');
    }

    final nativeResult = await _channel.invokeMapMethod<String, Object?>(
      'diagnose',
      <String, Object?>{'displacementZ': displacementZ},
    );
    if (nativeResult == null) {
      throw StateError('네이티브 모델 추론 결과가 없습니다.');
    }

    final probabilities = (nativeResult['probabilities'] as List<Object?>)
        .map((value) => (value as num).toDouble())
        .toList(growable: false);
    final classLabels = (nativeResult['classLabels'] as List<Object?>)
        .map((value) => value.toString())
        .toList(growable: false);
    final logits = (nativeResult['logits'] as List<Object?>?)
            ?.map((value) => (value as num).toDouble())
            .toList(growable: false) ??
        const <double>[];

    return DiagnosisResult(
      classLabels: classLabels,
      probabilities: _normalized(probabilities),
      logits: logits,
    );
  }

  /// 데모/화면 확인용 mock 진단 결과(B, H, IR, OR 확률).
  DiagnosisResult mockResult() {
    return const DiagnosisResult(
      classLabels: ['B', 'H', 'IR', 'OR'],
      probabilities: [0.08, 0.12, 0.70, 0.10],
    );
  }

  List<double> _normalized(List<double> values) {
    final sum = values.fold<double>(0, (total, value) => total + value);
    if (sum > 0) {
      return values.map((value) => value / sum).toList(growable: false);
    }

    final expValues = values.map(math.exp).toList(growable: false);
    final expSum = expValues.fold<double>(0, (total, value) => total + value);
    if (expSum == 0) {
      return List<double>.filled(values.length, 0);
    }
    return expValues.map((value) => value / expSum).toList(growable: false);
  }
}
