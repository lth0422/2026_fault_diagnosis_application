import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/video_info.dart';
import '../services/video_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/top_notice.dart';
import 'roi_setting_page.dart';

/// STEP 3 — 영상 정보(해상도/FPS) 입력.
/// (기존 Android: VideoSizeActivity — width/height/fps 입력 + 프리셋 버튼)
class VideoInfoPage extends StatefulWidget {
  const VideoInfoPage({super.key});

  static const String routeName = '/video-info';

  @override
  State<VideoInfoPage> createState() => _VideoInfoPageState();
}

class _VideoInfoPageState extends State<VideoInfoPage> {
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _fpsController = TextEditingController();
  bool _isLoadingMetadata = false;
  bool _hasEditedResolution = false;
  bool _hasConfirmed = false;
  (int, int)? _selectedResolution;
  String? _metadataError;

  @override
  void initState() {
    super.initState();
    final videoInfo = context.read<DiagnosisSession>().videoInfo;
    _applyVideoInfo(videoInfo);
    _loadSelectedVideoMetadata(videoInfo);
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _fpsController.dispose();
    super.dispose();
  }

  void _applyVideoInfo(VideoInfo? videoInfo) {
    if (videoInfo == null) {
      return;
    }

    if (videoInfo.width > 0) {
      _widthController.text = '${videoInfo.width}';
    }
    if (videoInfo.height > 0) {
      _heightController.text = '${videoInfo.height}';
    }
    if (videoInfo.fps > 0) {
      _fpsController.text = _formatFps(videoInfo.fps);
    }
  }

  String _formatFps(double fps) {
    if (fps == fps.roundToDouble()) {
      return fps.toInt().toString();
    }
    return fps.toString();
  }

  Future<void> _loadSelectedVideoMetadata(VideoInfo? selectedVideo) async {
    final path = selectedVideo?.path;
    if (path == null || path.isEmpty) {
      return;
    }
    if (selectedVideo!.width > 0 && selectedVideo.height > 0) {
      return;
    }

    setState(() {
      _isLoadingMetadata = true;
      _metadataError = null;
    });

    try {
      final loaded = await VideoService().loadVideoInfo(
        path,
        sourceUri: selectedVideo.sourceUri,
        displayName: selectedVideo.displayName,
      );
      if (!mounted) {
        return;
      }

      if (_hasConfirmed) {
        return;
      }

      context.read<DiagnosisSession>().setVideoInfo(loaded);
      if (!_hasEditedResolution) {
        _applyVideoInfo(loaded);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _metadataError = '영상 정보를 자동으로 읽지 못했습니다. 값을 직접 입력해주세요.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingMetadata = false);
      }
    }
  }

  void _applyResolution(int width, int height) {
    setState(() {
      _hasEditedResolution = true;
      _selectedResolution = (width, height);
      _widthController.text = '$width';
      _heightController.text = '$height';
    });
  }

  void _onResolutionChanged(String _) {
    if (_hasEditedResolution && _selectedResolution == null) {
      return;
    }
    setState(() {
      _hasEditedResolution = true;
      _selectedResolution = null;
    });
  }

  void _applyFps(int fps) => _fpsController.text = '$fps';

  void _confirm() {
    final width = int.tryParse(_widthController.text);
    final height = int.tryParse(_heightController.text);
    final fps = double.tryParse(_fpsController.text);

    if (width == null ||
        height == null ||
        fps == null ||
        width <= 0 ||
        height <= 0 ||
        fps <= 0) {
      showTopNotice(context, '올바른 값을 입력해주세요.');
      return;
    }

    final session = context.read<DiagnosisSession>();
    final current = session.videoInfo ?? const VideoInfo();
    final frameCount = current.durationMs > 0
        ? (current.durationMs / 1000 * fps).round()
        : current.frameCount;

    session.setVideoInfo(
      current.copyWith(
        width: width,
        height: height,
        fps: fps,
        frameCount: frameCount,
      ),
    );
    _hasConfirmed = true;
    Navigator.pushNamed(context, RoiSettingPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final selectedVideo = context.watch<DiagnosisSession>().videoInfo;
    final selectedLabel = selectedVideo?.displayName ?? selectedVideo?.path;

    return Scaffold(
      appBar: AppBar(title: const Text('영상 정보')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 3,
              total: 9,
              title: '영상 정보',
              description: '해상도(가로/세로)와 FPS 를 입력합니다.',
            ),
            if (selectedLabel != null) ...[
              Card(
                child: ListTile(
                  leading: const Icon(Icons.video_file),
                  title: const Text('선택된 영상'),
                  subtitle: Text(
                    _isLoadingMetadata
                        ? '$selectedLabel\n영상 정보 읽는 중...'
                        : selectedLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_metadataError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _metadataError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
            ],
            Expanded(
              child: ListView(
                children: [
                  _field(
                    '가로 (width)',
                    _widthController,
                    onChanged: _onResolutionChanged,
                  ),
                  _field(
                    '세로 (height)',
                    _heightController,
                    onChanged: _onResolutionChanged,
                  ),
                  _field('FPS', _fpsController),
                  const SizedBox(height: 8),
                  const Text('해상도 프리셋'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyResolution(1920, 1080),
                        style: _resolutionButtonStyle(1920, 1080),
                        child: const Text('1080 세로 (1920x1080)'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(1080, 1920),
                        style: _resolutionButtonStyle(1080, 1920),
                        child: const Text('1080 가로 (1080x1920)'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(1280, 720),
                        style: _resolutionButtonStyle(1280, 720),
                        child: const Text('720 세로 (1280x720)'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyResolution(720, 1280),
                        style: _resolutionButtonStyle(720, 1280),
                        child: const Text('720 가로 (720x1280)'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('FPS 프리셋'),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => _applyFps(120),
                        child: const Text('120'),
                      ),
                      OutlinedButton(
                        onPressed: () => _applyFps(240),
                        child: const Text('240'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PrimaryButton(
              label: '다음',
              liftFromSystemNav: true,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  ButtonStyle? _resolutionButtonStyle(int width, int height) {
    if (_selectedResolution != (width, height)) {
      return null;
    }
    return OutlinedButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
