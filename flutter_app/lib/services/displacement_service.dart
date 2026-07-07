import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/diagnosis_session.dart';
import '../models/displacement_result.dart';

/// 변위(DisplacementZ) 계산 서비스.
///
/// Android/iOS에서는 OpenCV 네이티브 MethodChannel로 마커 추적 기반 변위를 계산한다.
/// 데스크톱/웹 등 미구현 플랫폼에서는 [mockResult]를 fallback으로 사용한다.
class DisplacementService {
  static const MethodChannel _channel = MethodChannel(
    'fault_diagnosis/displacement',
  );
  static const EventChannel _progressChannel = EventChannel(
    'fault_diagnosis/displacement_progress',
  );

  Stream<DisplacementProgress> watchProgress() {
    return _progressChannel.receiveBroadcastStream().map((event) {
      final map = Map<Object?, Object?>.from(event as Map<Object?, Object?>);
      return DisplacementProgress(
        processed: (map['processed'] as num?)?.toInt() ?? 0,
        total: (map['total'] as num?)?.toInt() ?? 0,
        progress: (map['progress'] as num?)?.toDouble() ?? 0,
        detected: (map['detected'] as num?)?.toInt() ?? 0,
        missed: (map['missed'] as num?)?.toInt() ?? 0,
      );
    });
  }

  Future<void> shareCsv(DisplacementResult result) async {
    final csvUri = result.csvUri;
    if (csvUri == null || csvUri.isEmpty) {
      throw StateError('공유할 CSV 파일이 없습니다.');
    }
    await _channel.invokeMethod<bool>(
      'shareCsv',
      <String, Object?>{
        'csvUri': csvUri,
        'displayName': result.csvDisplayName,
      },
    );
  }

  Future<DisplacementResult> computeDisplacement(
      DiagnosisSession session) async {
    final isNativeSupported = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isNativeSupported) {
      return mockResult();
    }

    final videoInfo = session.videoInfo;
    final roiInfo = session.roiInfo;
    final hsvRange = session.hsvRange;
    final marker = session.markers.firstOrNull;
    final center = marker?.center;

    if (videoInfo?.path == null || videoInfo!.path!.isEmpty) {
      throw StateError('선택된 영상이 없습니다.');
    }
    if (roiInfo == null || roiInfo.isEmpty) {
      throw StateError('ROI 정보가 없습니다.');
    }
    if (hsvRange == null) {
      throw StateError('HSV 범위 정보가 없습니다.');
    }
    if (marker == null || center == null) {
      throw StateError('마커 중심 정보가 없습니다.');
    }

    final nativeResult = await _channel.invokeMapMethod<String, Object?>(
      'computeDisplacement',
      <String, Object?>{
        'videoPath': videoInfo.path,
        'roiX': roiInfo.x,
        'roiY': roiInfo.y,
        'roiWidth': roiInfo.width,
        'roiHeight': roiInfo.height,
        'hMin': hsvRange.hMin,
        'hMax': hsvRange.hMax,
        'sMin': hsvRange.sMin,
        'sMax': hsvRange.sMax,
        'vMin': hsvRange.vMin,
        'vMax': hsvRange.vMax,
        'markerX': center.dx,
        'markerY': center.dy,
        'markerXRatio': marker.normalizedCenter?.dx,
        'markerYRatio': marker.normalizedCenter?.dy,
        'trackingBoxSize': marker.trackingBoxSize,
        'trackingBoxSizeRatio': marker.normalizedTrackingBoxSize,
        'fps': videoInfo.fps,
      },
    );

    if (nativeResult == null) {
      throw StateError('네이티브 변위 계산 결과가 없습니다.');
    }

    final values = (nativeResult['displacementZ'] as List<Object?>)
        .map((value) => (value as num).toDouble())
        .toList(growable: false);
    return DisplacementResult(
      displacementZ: values,
      csvUri: nativeResult['csvUri'] as String?,
      csvDisplayName: nativeResult['csvDisplayName'] as String?,
      rawLength: (nativeResult['rawLength'] as num?)?.toInt() ?? values.length,
      detectedFrameCount:
          (nativeResult['detectedFrameCount'] as num?)?.toInt() ?? 0,
      missedFrameCount:
          (nativeResult['missedFrameCount'] as num?)?.toInt() ?? 0,
      zStdDev: (nativeResult['zStdDev'] as num?)?.toDouble() ?? 0,
    );
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

class DisplacementProgress {
  final int processed;
  final int total;
  final double progress;
  final int detected;
  final int missed;

  const DisplacementProgress({
    required this.processed,
    required this.total,
    required this.progress,
    required this.detected,
    required this.missed,
  });
}
