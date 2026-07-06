import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/marker_info.dart';
import '../services/hsv_preview_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/top_notice.dart';
import 'displacement_page.dart';

/// STEP 7 — 마커 중심점 지정.
/// (기존 Android: MarkerCenterActivity — 이미지 탭으로 마커 지정, ROI 크기 SeekBar, 확인/되돌리기)
class MarkerCenterPage extends StatefulWidget {
  const MarkerCenterPage({super.key});

  static const String routeName = '/marker-center';

  @override
  State<MarkerCenterPage> createState() => _MarkerCenterPageState();
}

class _MarkerCenterPageState extends State<MarkerCenterPage> {
  static const double _defaultTrackingBoxSize = 80;
  static const double _maxTrackingBoxSize = 300;

  final HsvPreviewService _previewService = HsvPreviewService();

  HsvPreviewFrame? _roiFrame;
  Offset? _markerCenter;
  double _trackingBoxSize = _defaultTrackingBoxSize;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final marker = context.read<DiagnosisSession>().markers.firstOrNull;
    _markerCenter = marker?.center;
    _trackingBoxSize = marker?.trackingBoxSize ?? _defaultTrackingBoxSize;
    _loadRoiFrame();
  }

  Future<void> _loadRoiFrame() async {
    final session = context.read<DiagnosisSession>();
    final videoInfo = session.videoInfo;
    final roiInfo = session.roiInfo;

    if (videoInfo == null || roiInfo == null || roiInfo.isEmpty) {
      setState(() => _errorMessage = '영상 또는 ROI 정보가 없습니다.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final frame = await _previewService.loadRoiFrame(
        videoInfo: videoInfo,
        roiInfo: roiInfo,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _roiFrame = frame;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'ROI 첫 프레임을 표시하지 못했습니다.';
      });
    }
  }

  void _setMarkerFromLocalPosition(Offset localPosition, Size viewSize) {
    final frame = _roiFrame;
    if (frame == null || viewSize.width <= 0 || viewSize.height <= 0) {
      return;
    }

    final x = (localPosition.dx / viewSize.width * frame.width)
        .clamp(0.0, frame.width.toDouble());
    final y = (localPosition.dy / viewSize.height * frame.height)
        .clamp(0.0, frame.height.toDouble());
    setState(() => _markerCenter = Offset(x, y));
  }

  void _undoMarker() {
    if (_markerCenter == null) {
      showTopNotice(context, '제거할 마커가 없습니다.');
      return;
    }
    setState(() => _markerCenter = null);
  }

  void _confirmMarker() {
    final center = _markerCenter;
    if (center == null) {
      showTopNotice(context, '마커 중심을 선택해주세요.');
      return;
    }

    context.read<DiagnosisSession>().setMarkers(
      <MarkerInfo>[
        MarkerInfo(
          id: 1,
          colorValue: _markerColorValue(context.read<DiagnosisSession>()),
          center: center,
          trackingBoxSize: _trackingBoxSize,
        ),
      ],
    );
    Navigator.pushNamed(context, DisplacementPage.routeName);
  }

  int _markerColorValue(DiagnosisSession session) {
    switch (session.markerColorKey) {
      case 'BLUE':
        return 0xFF2196F3;
      case 'GREEN':
        return 0xFF4CAF50;
      case 'WHITE':
        return 0xFFFFFFFF;
      case 'YELLOW':
        return 0xFFFFEB3B;
      case 'RED':
        return 0xFFF44336;
      default:
        return 0xFF00E676;
    }
  }

  @override
  Widget build(BuildContext context) {
    final frame = _roiFrame;

    return Scaffold(
      appBar: AppBar(title: const Text('마커 중심')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 7,
              total: 9,
              title: '마커 중심',
              description: 'ROI 이미지에서 마커 중심을 지정하고 추적 박스 크기를 설정합니다.',
            ),
            Expanded(
              child: Center(
                child: _buildMarkerEditor(frame),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '추적 박스 크기: ${_trackingBoxSize.round()} px',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Slider(
              value: _trackingBoxSize,
              min: 5,
              max: _maxTrackingBoxSize,
              divisions: (_maxTrackingBoxSize - 5).round(),
              label: '${_trackingBoxSize.round()} px',
              onChanged: (value) {
                setState(() => _trackingBoxSize = value);
              },
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _undoMarker,
                        child: const Text('되돌리기'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: '확인',
                      onPressed: _confirmMarker,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerEditor(HsvPreviewFrame? frame) {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (frame == null) {
      return AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(_errorMessage ?? 'ROI 프레임 없음')),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: frame.width / frame.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewSize = Size(constraints.maxWidth, constraints.maxHeight);

          return GestureDetector(
            onTapDown: (details) {
              _setMarkerFromLocalPosition(details.localPosition, viewSize);
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    frame.bytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                  CustomPaint(
                    painter: _MarkerCenterPainter(
                      center: _markerCenter,
                      imageSize: Size(
                        frame.width.toDouble(),
                        frame.height.toDouble(),
                      ),
                      trackingBoxSize: _trackingBoxSize,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarkerCenterPainter extends CustomPainter {
  final Offset? center;
  final Size imageSize;
  final double trackingBoxSize;

  const _MarkerCenterPainter({
    required this.center,
    required this.imageSize,
    required this.trackingBoxSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final marker = center;
    if (marker == null || imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final screenCenter = Offset(marker.dx * scaleX, marker.dy * scaleY);
    final screenBoxWidth = trackingBoxSize * scaleX;
    final screenBoxHeight = trackingBoxSize * scaleY;

    final boxRect = Rect.fromCenter(
      center: screenCenter,
      width: screenBoxWidth,
      height: screenBoxHeight,
    );

    final boxPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawRect(boxRect, boxPaint);

    final crossPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.5;
    const crossHalfLength = 24.0;
    const crossGap = 6.0;

    canvas.drawLine(
      screenCenter.translate(-crossHalfLength, 0),
      screenCenter.translate(-crossGap, 0),
      crossPaint,
    );
    canvas.drawLine(
      screenCenter.translate(crossGap, 0),
      screenCenter.translate(crossHalfLength, 0),
      crossPaint,
    );
    canvas.drawLine(
      screenCenter.translate(0, -crossHalfLength),
      screenCenter.translate(0, -crossGap),
      crossPaint,
    );
    canvas.drawLine(
      screenCenter.translate(0, crossGap),
      screenCenter.translate(0, crossHalfLength),
      crossPaint,
    );

    final ringPaint = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(screenCenter, 10, ringPaint);

    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(screenCenter, 3.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _MarkerCenterPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.trackingBoxSize != trackingBoxSize;
  }
}
