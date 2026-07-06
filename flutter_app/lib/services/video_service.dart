import 'dart:io';

import 'package:video_player/video_player.dart';

import '../models/video_info.dart';

/// 영상 메타데이터 로딩 서비스.
class VideoService {
  /// 지정한 경로의 영상 메타데이터를 로드한다.
  Future<VideoInfo> loadVideoInfo(
    String path, {
    String? sourceUri,
    String? displayName,
  }) async {
    final controller = VideoPlayerController.file(File(path));

    try {
      await controller.initialize();
      final value = controller.value;
      final size = value.size;

      return VideoInfo(
        path: path,
        sourceUri: sourceUri,
        displayName: displayName,
        width: size.width.round(),
        height: size.height.round(),
        durationMs: value.duration.inMilliseconds,
      );
    } finally {
      await controller.dispose();
    }
  }
}
