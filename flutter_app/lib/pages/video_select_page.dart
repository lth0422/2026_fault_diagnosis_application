import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/video_info.dart';
import '../services/file_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/top_notice.dart';
import 'video_info_page.dart';

/// STEP 2 — 진단 대상 영상 선택.
/// (기존 Android: MainActivity — 갤러리에서 영상 선택 후 VideoSizeActivity 로 이동)
class VideoSelectPage extends StatefulWidget {
  const VideoSelectPage({super.key});

  static const String routeName = '/video-select';

  @override
  State<VideoSelectPage> createState() => _VideoSelectPageState();
}

class _VideoSelectPageState extends State<VideoSelectPage> {
  bool _isPicking = false;

  Future<void> _pickVideo() async {
    if (_isPicking) {
      return;
    }

    setState(() => _isPicking = true);
    try {
      final video = await FileService().pickVideo();
      if (!mounted || video == null) {
        return;
      }

      context.read<DiagnosisSession>().setVideoInfo(video);
      showTopNotice(
        context,
        "'${video.displayName ?? video.path}'을(를) 선택했습니다.",
        icon: Icons.check_circle_outline,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopNotice(context, '영상 선택 실패: $error', icon: Icons.error_outline);
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _goNext(VideoInfo? videoInfo) {
    if (videoInfo == null || videoInfo.isEmpty) {
      showTopNotice(context, '먼저 진단할 영상을 선택해주세요.');
      return;
    }

    Navigator.pushNamed(context, VideoInfoPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final videoInfo = context.watch<DiagnosisSession>().videoInfo;
    final selectedLabel = videoInfo?.displayName ?? videoInfo?.path;

    return Scaffold(
      appBar: AppBar(title: const Text('영상 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 2,
              total: 9,
              title: '영상 선택',
              description: '갤러리에서 진단할 영상을 선택합니다.',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: _isPicking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_library),
                      label: Text(_isPicking ? '영상 선택 중...' : '갤러리에서 영상 선택'),
                      onPressed: _isPicking ? null : _pickVideo,
                    ),
                    if (selectedLabel != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: '다음',
              liftFromSystemNav: true,
              onPressed: () => _goNext(videoInfo),
            ),
          ],
        ),
      ),
    );
  }
}
