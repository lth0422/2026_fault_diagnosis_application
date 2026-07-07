import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/roi_info.dart';
import '../models/video_info.dart';
import '../services/hsv_preview_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/roi_painter.dart';
import '../widgets/top_notice.dart';
import 'marker_color_page.dart';

/// STEP 4 — 관심 영역(ROI) 설정.
/// (기존 Android: ROIActivity — 첫 프레임 위에 사각형 드래그, 자르기/리셋/완료)
class RoiSettingPage extends StatefulWidget {
  const RoiSettingPage({super.key});

  static const String routeName = '/roi';

  @override
  State<RoiSettingPage> createState() => _RoiSettingPageState();
}

class _RoiSettingPageState extends State<RoiSettingPage> {
  Future<HsvPreviewFrame>? _loadFirstFrame;
  RoiInfo? _roi;
  Offset? _dragStart;
  bool _isCropPreview = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    final session = context.read<DiagnosisSession>();
    _roi = session.roiInfo;
    _initializeSelectedVideo(session.videoInfo);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeSelectedVideo(VideoInfo? videoInfo) {
    final path = videoInfo?.path;
    if (path == null || path.isEmpty) {
      _videoError = '선택된 영상이 없습니다.';
      return;
    }

    _loadFirstFrame = HsvPreviewService()
        .loadRoiFrame(
      videoInfo: videoInfo!,
      roiInfo: const RoiInfo(x: 0, y: 0, width: 1, height: 1),
    )
        .then((frame) {
      if (frame.bytes.isEmpty || frame.width <= 0 || frame.height <= 0) {
        throw StateError('첫 프레임을 읽지 못했습니다.');
      }
      return frame;
    }).catchError((Object error) {
      _videoError = '영상을 표시하지 못했습니다.';
      if (mounted) {
        setState(() {});
      }
      throw error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final videoInfo = context.watch<DiagnosisSession>().videoInfo;
    final roi = _roi;

    return Scaffold(
      appBar: AppBar(title: const Text('ROI 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 4,
              total: 9,
              title: 'ROI 설정',
              description: '첫 프레임 위에서 관심 영역(ROI)을 드래그로 지정합니다.',
            ),
            Expanded(
              child: Center(
                child: _buildRoiEditor(videoInfo),
              ),
            ),
            if (roi != null && !roi.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _roiLabel(roi, videoInfo),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        roi == null || roi.isEmpty ? null : _toggleCropPreview,
                    child: Text(_isCropPreview ? '원본 보기' : '자르기'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetRoi,
                    child: const Text('리셋'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: '완료',
              liftFromSystemNav: true,
              onPressed: _confirmRoi,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoiEditor(VideoInfo? videoInfo) {
    if (_videoError != null) {
      return _buildPlaceholder(_videoError!);
    }

    return FutureBuilder<HsvPreviewFrame>(
      future: _loadFirstFrame,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const CircularProgressIndicator();
        }

        final frame = snapshot.data;
        if (snapshot.hasError || frame == null || frame.bytes.isEmpty) {
          return _buildPlaceholder('영상을 표시하지 못했습니다.');
        }

        return AspectRatio(
          aspectRatio: frame.width / frame.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);

              return GestureDetector(
                onPanStart: (details) {
                  _dragStart = _clampOffset(details.localPosition, size);
                  setState(() {
                    _isCropPreview = false;
                    _roi = const RoiInfo();
                  });
                },
                onPanUpdate: (details) {
                  final start = _dragStart;
                  if (start == null) {
                    return;
                  }

                  final current = _clampOffset(details.localPosition, size);
                  setState(() {
                    _roi = _roiFromOffsets(start, current, size);
                  });
                },
                onPanEnd: (_) {
                  final roi = _roi;
                  if (roi == null || roi.width < 0.01 || roi.height < 0.01) {
                    setState(() => _roi = const RoiInfo());
                  }
                  _dragStart = null;
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      frame.bytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                    ),
                    CustomPaint(
                      foregroundPainter: RoiPainter(
                        roi: _roi,
                        drawBackground: false,
                        dimOutside: _isCropPreview,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(String message) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(
        painter: RoiPainter(roi: _roi),
        child: Center(child: Text(message)),
      ),
    );
  }

  Offset _clampOffset(Offset offset, Size size) {
    return Offset(
      offset.dx.clamp(0, size.width).toDouble(),
      offset.dy.clamp(0, size.height).toDouble(),
    );
  }

  RoiInfo _roiFromOffsets(Offset start, Offset end, Size size) {
    final left = start.dx < end.dx ? start.dx : end.dx;
    final top = start.dy < end.dy ? start.dy : end.dy;
    final right = start.dx > end.dx ? start.dx : end.dx;
    final bottom = start.dy > end.dy ? start.dy : end.dy;

    return RoiInfo(
      x: left / size.width,
      y: top / size.height,
      width: (right - left) / size.width,
      height: (bottom - top) / size.height,
    );
  }

  String _roiLabel(RoiInfo roi, VideoInfo? videoInfo) {
    final width = videoInfo?.width ?? 0;
    final height = videoInfo?.height ?? 0;
    if (width <= 0 || height <= 0) {
      return 'ROI: x=${roi.x.toStringAsFixed(3)}, y=${roi.y.toStringAsFixed(3)}, '
          'w=${roi.width.toStringAsFixed(3)}, h=${roi.height.toStringAsFixed(3)}';
    }

    final left = (roi.x * width).round();
    final top = (roi.y * height).round();
    final right = ((roi.x + roi.width) * width).round();
    final bottom = ((roi.y + roi.height) * height).round();

    return 'ROI: left=$left, top=$top, right=$right, bottom=$bottom';
  }

  void _toggleCropPreview() {
    setState(() => _isCropPreview = !_isCropPreview);
  }

  void _resetRoi() {
    setState(() {
      _roi = const RoiInfo();
      _isCropPreview = false;
      _dragStart = null;
    });
  }

  void _confirmRoi() {
    final roi = _roi;
    if (roi == null || roi.isEmpty) {
      showTopNotice(context, '유효한 ROI 영역을 선택해주세요.');
      return;
    }

    context.read<DiagnosisSession>().setRoiInfo(roi);
    Navigator.pushNamed(context, MarkerColorPage.routeName);
  }
}
