import 'package:flutter/material.dart';

import '../models/roi_info.dart';

/// ROI(관심 영역) 사각형을 그리는 CustomPainter (플레이스홀더).
///
/// [roi]의 좌표/크기는 0.0~1.0 정규화 값으로 가정하며 캔버스 크기에 맞춰 렌더링한다.
/// 1차 마일스톤에서는 실제 영상 위에 그리지 않고, 배경 박스 위에 예시로 표시한다.
class RoiPainter extends CustomPainter {
  final RoiInfo? roi;
  final bool drawBackground;
  final bool dimOutside;

  RoiPainter({
    this.roi,
    this.drawBackground = true,
    this.dimOutside = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawBackground) {
      // 배경 (영상 프레임 자리 표시자)
      final background = Paint()..color = Colors.black12;
      canvas.drawRect(Offset.zero & size, background);
    }

    final RoiInfo effective = (roi == null || roi!.isEmpty)
        // 미설정 시 화면 중앙에 예시 ROI 표시
        ? const RoiInfo(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        : roi!;

    final rect = Rect.fromLTWH(
      effective.x * size.width,
      effective.y * size.height,
      effective.width * size.width,
      effective.height * size.height,
    );

    if (dimOutside && roi != null && !roi!.isEmpty) {
      final overlay = Path()..addRect(Offset.zero & size);
      final hole = Path()..addRect(rect);
      final dimPaint = Paint()..color = Colors.black.withValues(alpha: 0.35);
      canvas.drawPath(
        Path.combine(PathOperation.difference, overlay, hole),
        dimPaint,
      );
    }

    final border = Paint()
      ..color = Colors.lightGreenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRect(rect, border);
  }

  @override
  bool shouldRepaint(covariant RoiPainter oldDelegate) =>
      oldDelegate.roi != roi ||
      oldDelegate.drawBackground != drawBackground ||
      oldDelegate.dimOutside != dimOutside;
}
