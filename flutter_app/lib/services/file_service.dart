import '../models/video_info.dart';

/// 파일/영상 선택 관련 서비스 (스텁).
///
/// ⚠️ 1차 마일스톤에서는 실제 파일 선택을 구현하지 않는다.
/// 이후 file_picker / image_picker 등으로 대체 예정.
class FileService {
  /// 진단 대상 영상을 선택한다.
  ///
  /// TODO(마일스톤 2): 실제 파일 선택 구현.
  Future<VideoInfo?> pickVideo() {
    throw UnimplementedError('영상 선택은 아직 구현되지 않았습니다. (마일스톤 2 예정)');
  }
}
