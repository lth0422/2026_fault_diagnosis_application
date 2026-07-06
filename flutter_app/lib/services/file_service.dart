import '../models/video_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 파일/영상 선택 관련 서비스.
class FileService {
  static const MethodChannel _channel = MethodChannel(
    'fault_diagnosis/file_metadata',
  );

  /// 진단 대상 영상을 선택한다.
  Future<VideoInfo?> pickVideo() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _pickAndroidLocalVideo();
    }

    final result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    final path = file.path;
    final sourceUri = file.identifier;
    final displayName = await _resolveDisplayName(
      currentName: file.name,
      path: path,
      sourceUri: sourceUri,
    );

    if (path == null || path.isEmpty) {
      return VideoInfo(sourceUri: sourceUri, displayName: displayName);
    }

    return VideoInfo(
        path: path, sourceUri: sourceUri, displayName: displayName);
  }

  Future<VideoInfo?> _pickAndroidLocalVideo() async {
    final result = await _channel.invokeMapMethod<String, Object?>(
      'pickLocalVideo',
    );
    if (result == null) {
      return null;
    }

    final path = result['path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }

    return VideoInfo(
      path: path,
      sourceUri: result['sourceUri'] as String?,
      displayName: result['displayName'] as String?,
    );
  }

  Future<String> _resolveDisplayName({
    required String currentName,
    required String? path,
    required String? sourceUri,
  }) async {
    try {
      final resolved = await _channel.invokeMethod<String>(
        'resolveDisplayName',
        <String, Object?>{
          'currentName': currentName,
          'path': path,
          'sourceUri': sourceUri,
        },
      );
      if (resolved != null && resolved.trim().isNotEmpty) {
        return resolved;
      }
    } catch (_) {
      // 표시명 복원 실패는 파일 선택 실패로 취급하지 않는다.
    }
    return currentName;
  }
}
