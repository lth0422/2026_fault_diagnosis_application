/// 선택된 영상의 메타데이터를 표현하는 모델.
///
/// 1차 마일스톤에서는 실제 영상 로딩을 수행하지 않으며,
/// 화면 흐름과 데이터 구조 확인용으로만 사용한다.
class VideoInfo {
  /// 영상 파일 경로 (미선택 시 null).
  final String? path;

  /// Android/iOS 파일 선택기가 제공한 원본 식별자(content URI 등).
  final String? sourceUri;

  /// 화면에 표시할 영상 파일명.
  final String? displayName;

  /// 프레임 가로 픽셀 수.
  final int width;

  /// 프레임 세로 픽셀 수.
  final int height;

  /// 초당 프레임 수.
  final double fps;

  /// 전체 프레임 수.
  final int frameCount;

  /// 영상 길이(밀리초).
  final int durationMs;

  const VideoInfo({
    this.path,
    this.sourceUri,
    this.displayName,
    this.width = 0,
    this.height = 0,
    this.fps = 0,
    this.frameCount = 0,
    this.durationMs = 0,
  });

  bool get isEmpty => path == null;

  VideoInfo copyWith({
    String? path,
    String? sourceUri,
    String? displayName,
    int? width,
    int? height,
    double? fps,
    int? frameCount,
    int? durationMs,
  }) {
    return VideoInfo(
      path: path ?? this.path,
      sourceUri: sourceUri ?? this.sourceUri,
      displayName: displayName ?? this.displayName,
      width: width ?? this.width,
      height: height ?? this.height,
      fps: fps ?? this.fps,
      frameCount: frameCount ?? this.frameCount,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  String toString() =>
      'VideoInfo(path: $path, sourceUri: $sourceUri, displayName: $displayName, ${width}x$height, fps: $fps, frames: $frameCount)';
}
