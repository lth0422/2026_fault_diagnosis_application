import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/hsv_range.dart';
import '../services/hsv_preview_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import 'marker_center_page.dart';

/// STEP 6 — HSV 색상 범위 조정.
/// (기존 Android: HSVActivity — 6개 SeekBar 로 HSV 범위 조정, 미리보기, 확인)
class HsvSettingPage extends StatefulWidget {
  const HsvSettingPage({super.key});

  static const String routeName = '/hsv';

  @override
  State<HsvSettingPage> createState() => _HsvSettingPageState();
}

class _HsvSettingPageState extends State<HsvSettingPage> {
  // 기본값(기존 Android 프리셋): H 0~180, S/V 0~255.
  double _hMin = 0, _hMax = 180;
  double _sMin = 0, _sMax = 255;
  double _vMin = 0, _vMax = 255;
  final HsvPreviewService _previewService = HsvPreviewService();
  HsvPreviewFrame? _roiFrame;
  HsvPreviewResult? _previewResult;
  Timer? _previewDebounce;
  int _previewRequestId = 0;
  bool _isLoadingFrame = false;
  bool _isFiltering = false;
  String? _previewError;
  bool _showOriginalPreview = false;

  @override
  void initState() {
    super.initState();
    // 마커 색상 단계에서 선택된 프리셋이 있으면 초기값으로 사용.
    final preset = context.read<DiagnosisSession>().hsvRange;
    if (preset != null) {
      _hMin = preset.hMin;
      _hMax = preset.hMax;
      _sMin = preset.sMin;
      _sMax = preset.sMax;
      _vMin = preset.vMin;
      _vMax = preset.vMax;
    }
    _loadPreviewFrame();
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  void _confirm() {
    context.read<DiagnosisSession>().setHsvRange(
          HsvRange(
            hMin: _hMin,
            hMax: _hMax,
            sMin: _sMin,
            sMax: _sMax,
            vMin: _vMin,
            vMax: _vMax,
          ),
        );
    Navigator.pushNamed(context, MarkerCenterPage.routeName);
  }

  HsvRange get _currentHsvRange => HsvRange(
        hMin: _hMin,
        hMax: _hMax,
        sMin: _sMin,
        sMax: _sMax,
        vMin: _vMin,
        vMax: _vMax,
      );

  Future<void> _loadPreviewFrame() async {
    final session = context.read<DiagnosisSession>();
    final videoInfo = session.videoInfo;
    final roiInfo = session.roiInfo;

    if (videoInfo == null || roiInfo == null || roiInfo.isEmpty) {
      setState(() {
        _previewError = '영상 또는 ROI 정보가 없습니다.';
      });
      return;
    }

    setState(() {
      _isLoadingFrame = true;
      _previewError = null;
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
        _isLoadingFrame = false;
      });
      await _refreshPreview();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingFrame = false;
        _previewError = '첫 프레임 HSV 미리보기를 만들지 못했습니다.';
      });
    }
  }

  void _schedulePreviewRefresh() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 80),
      _refreshPreview,
    );
  }

  Future<void> _refreshPreview() async {
    final frame = _roiFrame;
    if (frame == null) {
      return;
    }

    final requestId = ++_previewRequestId;
    setState(() {
      _isFiltering = true;
      _previewError = null;
    });

    try {
      final result = await _previewService.applyHsvFilter(
        roiFrameBytes: frame.bytes,
        hsvRange: _currentHsvRange,
      );
      if (!mounted || requestId != _previewRequestId) {
        return;
      }
      setState(() {
        _previewResult = result;
        _isFiltering = false;
      });
    } catch (_) {
      if (!mounted || requestId != _previewRequestId) {
        return;
      }
      setState(() {
        _isFiltering = false;
        _previewError = 'HSV 필터를 적용하지 못했습니다.';
      });
    }
  }

  void _updateHRange(RangeValues values) {
    setState(() {
      _hMin = values.start;
      _hMax = values.end;
    });
    _schedulePreviewRefresh();
  }

  void _updateSRange(RangeValues values) {
    setState(() {
      _sMin = values.start;
      _sMax = values.end;
    });
    _schedulePreviewRefresh();
  }

  void _updateVRange(RangeValues values) {
    setState(() {
      _vMin = values.start;
      _vMax = values.end;
    });
    _schedulePreviewRefresh();
  }

  Color _markerSwatch(DiagnosisSession session) {
    if (session.markerColorKey == 'WHITE') {
      return Colors.white;
    }
    final hue = ((_hMin + _hMax) / 2).clamp(0.0, 180.0) * 2;
    return HSVColor.fromAHSV(1, hue, 0.85, 0.95).toColor();
  }

  String _rangeText(double min, double max) {
    return '${min.round()}-${max.round()}';
  }

  String _roiText(DiagnosisSession session) {
    final roi = session.roiInfo;
    final video = session.videoInfo;
    if (roi == null ||
        roi.isEmpty ||
        video == null ||
        video.width == 0 ||
        video.height == 0) {
      return 'ROI 정보 없음';
    }

    final left = (roi.x * video.width).round();
    final top = (roi.y * video.height).round();
    final right = ((roi.x + roi.width) * video.width).round();
    final bottom = ((roi.y + roi.height) * video.height).round();
    return 'ROI x:$left-$right, y:$top-$bottom';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<DiagnosisSession>();
    final colorScheme = Theme.of(context).colorScheme;
    final markerLabel = session.markerColorLabel ?? '기본값';
    final videoName = session.videoInfo?.displayName ?? '선택 영상';

    return Scaffold(
      appBar: AppBar(title: const Text('HSV 설정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 6,
              total: 9,
              title: 'HSV 설정',
              description: '선택한 마커 색상 프리셋을 기준으로 HSV 검출 범위를 조정합니다.',
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  _previewPanel(colorScheme),
                  const SizedBox(height: 16),
                  _contextPanel(
                    colorScheme: colorScheme,
                    markerLabel: markerLabel,
                    swatch: _markerSwatch(session),
                    videoName: videoName,
                    roiText: _roiText(session),
                  ),
                  const SizedBox(height: 16),
                  _rangePanel(
                    colorScheme: colorScheme,
                    hsvText: 'H ${_rangeText(_hMin, _hMax)} / '
                        'S ${_rangeText(_sMin, _sMax)} / '
                        'V ${_rangeText(_vMin, _vMax)}',
                  ),
                  const SizedBox(height: 12),
                  _rangeSlider(
                    label: 'H',
                    values: RangeValues(_hMin, _hMax),
                    max: 180,
                    onChanged: _updateHRange,
                  ),
                  _rangeSlider(
                    label: 'S',
                    values: RangeValues(_sMin, _sMax),
                    max: 255,
                    onChanged: _updateSRange,
                  ),
                  _rangeSlider(
                    label: 'V',
                    values: RangeValues(_vMin, _vMax),
                    max: 255,
                    onChanged: _updateVRange,
                  ),
                ],
              ),
            ),
            PrimaryButton(
              label: '확인',
              liftFromSystemNav: true,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewPanel(ColorScheme colorScheme) {
    final frame = _roiFrame;
    final previewBytes = _previewResult?.bytes;
    final displayBytes = _showOriginalPreview ? frame?.bytes : previewBytes;
    final aspectRatio = frame == null || frame.height == 0
        ? 16 / 9
        : frame.width / frame.height;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: displayBytes == null
                  ? ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Text(
                          _previewError ?? '첫 프레임 준비 중',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  : Image.memory(
                      displayBytes,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SegmentedButton<bool>(
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      selectedBackgroundColor: Colors.white,
                      selectedForegroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    segments: const [
                      ButtonSegment(value: false, label: Text('검출')),
                      ButtonSegment(value: true, label: Text('원본')),
                    ],
                    selected: <bool>{_showOriginalPreview},
                    onSelectionChanged: (values) {
                      setState(() => _showOriginalPreview = values.first);
                    },
                  ),
                ),
              ),
            ),
            if (_isLoadingFrame || _isFiltering)
              const Positioned(
                right: 12,
                top: 12,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (_previewResult != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      '검출 ${_previewResult!.detectedPixels}/${_previewResult!.totalPixels} '
                      '(${(_previewResult!.detectedRatio * 100).toStringAsFixed(1)}%)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (_previewError != null && previewBytes != null)
              Positioned(
                right: 8,
                bottom: 8,
                child: Icon(
                  Icons.error_outline,
                  color: colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _contextPanel({
    required ColorScheme colorScheme,
    required String markerLabel,
    required Color swatch,
    required String videoName,
    required String roiText,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: swatch,
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    markerLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _infoLine('영상', videoName),
            const SizedBox(height: 6),
            _infoLine('영역', roiText),
          ],
        ),
      ),
    );
  }

  Widget _rangePanel({
    required ColorScheme colorScheme,
    required String hsvText,
  }) {
    final result = _previewResult;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _infoLine('HSV', hsvText),
            if (result != null) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: result.detectedRatio.clamp(0, 1),
              ),
              const SizedBox(height: 6),
              Text(
                '검출 픽셀 ${result.detectedPixels} / ${result.totalPixels} '
                '(${(result.detectedRatio * 100).toStringAsFixed(2)}%)',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _rangeSlider({
    required String label,
    required RangeValues values,
    required double max,
    required ValueChanged<RangeValues> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${values.start.round()} - ${values.end.round()}'),
            ],
          ),
          RangeSlider(
            values: RangeValues(
              values.start.clamp(0, max),
              values.end.clamp(0, max),
            ),
            min: 0,
            max: max,
            divisions: max.toInt(),
            labels: RangeLabels(
              values.start.round().toString(),
              values.end.round().toString(),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
