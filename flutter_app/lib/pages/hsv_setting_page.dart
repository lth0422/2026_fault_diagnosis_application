import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/hsv_range.dart';
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
  // 기본값(기존 Android): H 0~179, S/V 0~255.
  double _hMin = 0, _hMax = 179;
  double _sMin = 0, _sMax = 255;
  double _vMin = 0, _vMax = 255;

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
  }

  void _confirm() {
    context.read<DiagnosisSession>().setHsvRange(
          HsvRange(
            hMin: _hMin, hMax: _hMax,
            sMin: _sMin, sMax: _sMax,
            vMin: _vMin, vMax: _vMax,
          ),
        );
    Navigator.pushNamed(context, MarkerCenterPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
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
              description: '마커 검출을 위한 HSV 색상 범위를 조정합니다. (미리보기는 이후 마일스톤)',
            ),
            Expanded(
              child: ListView(
                children: [
                  _slider('H min', _hMin, 179, (v) => setState(() => _hMin = v)),
                  _slider('H max', _hMax, 179, (v) => setState(() => _hMax = v)),
                  _slider('S min', _sMin, 255, (v) => setState(() => _sMin = v)),
                  _slider('S max', _sMax, 255, (v) => setState(() => _sMax = v)),
                  _slider('V min', _vMin, 255, (v) => setState(() => _vMin = v)),
                  _slider('V max', _vMax, 255, (v) => setState(() => _vMax = v)),
                ],
              ),
            ),
            PrimaryButton(label: '확인', onPressed: _confirm),
          ],
        ),
      ),
    );
  }

  Widget _slider(
      String label, double value, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 56, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            min: 0,
            max: max,
            divisions: max.toInt(),
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 36, child: Text(value.toInt().toString())),
      ],
    );
  }
}
