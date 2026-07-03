import 'package:flutter/material.dart';

import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/roi_painter.dart';
import 'marker_color_page.dart';

/// STEP 4 — 관심 영역(ROI) 설정 (플레이스홀더).
/// (기존 Android: ROIActivity — 첫 프레임 위에 사각형 드래그, 자르기/리셋/완료)
class RoiSettingPage extends StatelessWidget {
  const RoiSettingPage({super.key});

  static const String routeName = '/roi';

  @override
  Widget build(BuildContext context) {
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
              description:
                  '첫 프레임 위에서 관심 영역(ROI)을 지정합니다. (예시 표시, 실제 영상은 이후 마일스톤)',
            ),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CustomPaint(
                    painter: RoiPainter(),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: null, // 플레이스홀더: 실제 크롭 미구현
                    child: Text('자르기'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: null, // 플레이스홀더: 실제 리셋 미구현
                    child: Text('리셋'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: '완료',
              liftFromSystemNav: true,
              onPressed: () =>
                  Navigator.pushNamed(context, MarkerColorPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
