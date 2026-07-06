import 'package:flutter/foundation.dart';

import 'video_info.dart';
import 'roi_info.dart';
import 'hsv_range.dart';
import 'marker_info.dart';
import 'displacement_result.dart';
import 'diagnosis_result.dart';

/// 진단 워크플로우 전체의 상태를 보관하는 세션 모델.
///
/// 기존 Android 앱에서 Activity 간 Intent 로 전달하던 데이터를,
/// Flutter 에서는 하나의 [ChangeNotifier] 세션으로 관리한다.
/// (상태 관리: `provider` 패키지 사용)
class DiagnosisSession extends ChangeNotifier {
  VideoInfo? videoInfo;
  RoiInfo? roiInfo;
  String? markerColorKey;
  String? markerColorLabel;
  HsvRange? hsvRange;
  List<MarkerInfo> markers = <MarkerInfo>[];
  DisplacementResult? displacementResult;
  DiagnosisResult? diagnosisResult;

  void setVideoInfo(VideoInfo value) {
    videoInfo = value;
    notifyListeners();
  }

  void setRoiInfo(RoiInfo value) {
    roiInfo = value;
    notifyListeners();
  }

  void setHsvRange(HsvRange value) {
    hsvRange = value;
    notifyListeners();
  }

  void setMarkerColor({
    required String key,
    required String label,
    required HsvRange hsvRange,
  }) {
    markerColorKey = key;
    markerColorLabel = label;
    this.hsvRange = hsvRange;
    notifyListeners();
  }

  void setMarkers(List<MarkerInfo> value) {
    markers = value;
    notifyListeners();
  }

  void setDisplacementResult(DisplacementResult value) {
    displacementResult = value;
    notifyListeners();
  }

  void setDiagnosisResult(DiagnosisResult value) {
    diagnosisResult = value;
    notifyListeners();
  }

  /// 세션 초기화(처음 화면으로 돌아갈 때 사용).
  void reset() {
    videoInfo = null;
    roiInfo = null;
    markerColorKey = null;
    markerColorLabel = null;
    hsvRange = null;
    markers = <MarkerInfo>[];
    displacementResult = null;
    diagnosisResult = null;
    notifyListeners();
  }
}
