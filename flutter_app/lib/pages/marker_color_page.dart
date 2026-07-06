import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/hsv_range.dart';
import '../widgets/step_header.dart';
import 'hsv_setting_page.dart';

/// STEP 5 — 마커 색상 지정.
/// (기존 Android: MarkerColorActivity — 색상 선택 시 해당 HSV 프리셋을 HSVActivity 로 전달)
class MarkerColorPage extends StatelessWidget {
  const MarkerColorPage({super.key});

  static const String routeName = '/marker-color';

  /// 기존 Android COLOR_RANGES 와 동일한 색상별 HSV 프리셋.
  static const Map<String, HsvRange> colorRanges = {
    'BLUE': HsvRange(
      hMin: 100,
      hMax: 140,
      sMin: 150,
      sMax: 255,
      vMin: 50,
      vMax: 255,
    ),
    'GREEN': HsvRange(
      hMin: 35,
      hMax: 85,
      sMin: 150,
      sMax: 255,
      vMin: 50,
      vMax: 255,
    ),
    'WHITE': HsvRange(
      hMin: 0,
      hMax: 180,
      sMin: 0,
      sMax: 30,
      vMin: 200,
      vMax: 255,
    ),
    'YELLOW': HsvRange(
      hMin: 20,
      hMax: 35,
      sMin: 150,
      sMax: 255,
      vMin: 50,
      vMax: 255,
    ),
    'RED': HsvRange(
      hMin: 160,
      hMax: 180,
      sMin: 150,
      sMax: 255,
      vMin: 50,
      vMax: 255,
    ),
  };

  void _selectColor(BuildContext context, _ColorSpec spec) {
    context.read<DiagnosisSession>().setMarkerColor(
          key: spec.key,
          label: spec.label,
          hsvRange: colorRanges[spec.key]!,
        );
    Navigator.pushNamed(context, HsvSettingPage.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <_ColorSpec>[
      const _ColorSpec('BLUE', '파랑', Colors.blue),
      const _ColorSpec('GREEN', '초록', Colors.green),
      const _ColorSpec('WHITE', '흰색', Colors.white),
      const _ColorSpec('YELLOW', '노랑', Colors.yellow),
      const _ColorSpec('RED', '빨강', Colors.red),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('마커 색상')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 5,
              total: 9,
              title: '마커 색상',
              description: '추적할 마커의 색상을 선택합니다. 선택한 색상의 HSV 프리셋이 다음 단계에 적용됩니다.',
            ),
            Expanded(
              child: ListView.separated(
                itemCount: buttons.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final spec = buttons[i];
                  return SizedBox(
                    height: 72,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: spec.color,
                        foregroundColor: spec.color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
                      onPressed: () => _selectColor(context, spec),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(spec.label),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _formatRange(colorRanges[spec.key]!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRange(HsvRange range) {
    return 'H ${range.hMin.toInt()}-${range.hMax.toInt()} / '
        'S ${range.sMin.toInt()}-${range.sMax.toInt()} / '
        'V ${range.vMin.toInt()}-${range.vMax.toInt()}';
  }
}

class _ColorSpec {
  final String key;
  final String label;
  final Color color;
  const _ColorSpec(this.key, this.label, this.color);
}
