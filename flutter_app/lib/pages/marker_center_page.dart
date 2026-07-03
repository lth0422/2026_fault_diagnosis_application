import 'package:flutter/material.dart';

import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import 'displacement_page.dart';

/// STEP 7 — 마커 중심점 지정 (플레이스홀더).
/// (기존 Android: MarkerCenterActivity — 이미지 탭으로 마커 지정, ROI 크기 SeekBar, 확인/되돌리기)
class MarkerCenterPage extends StatefulWidget {
  const MarkerCenterPage({super.key});

  static const String routeName = '/marker-center';

  @override
  State<MarkerCenterPage> createState() => _MarkerCenterPageState();
}

class _MarkerCenterPageState extends State<MarkerCenterPage> {
  double _roiSize = 5; // 기존 Android 기본값 5, 범위 0~300

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              description: 'ROI 이미지에서 마커 중심을 지정하고 추적 박스 크기를 설정합니다. (예시 표시)',
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    color: Colors.black12,
                    child: Center(
                      child: Icon(Icons.add,
                          size: 48, color: theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('ROI 크기: ${_roiSize.toInt()} px'),
            Slider(
              value: _roiSize,
              min: 0,
              max: 300,
              divisions: 300,
              label: _roiSize.toInt().toString(),
              onChanged: (v) => setState(() => _roiSize = v),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: null, // 플레이스홀더: 실제 마커 제거 미구현
                        child: Text('되돌리기'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      label: '확인',
                      onPressed: () => Navigator.pushNamed(
                          context, DisplacementPage.routeName),
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
}
