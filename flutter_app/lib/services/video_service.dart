import '../models/video_info.dart';

/// 영상 메타데이터 로딩 서비스 (스텁).
///
/// ⚠️ 1차 마일스톤에서는 실제 영상 로딩을 구현하지 않는다.
class VideoService {
  /// 지정한 경로의 영상 메타데이터를 로드한다.
  ///
  /// TODO(마일스톤 2): 실제 영상 정보 로딩 구현.
  Future<VideoInfo> loadVideoInfo(String path) {
    throw UnimplementedError('영상 정보 로딩은 아직 구현되지 않았습니다. (마일스톤 2 예정)');
  }
}
