import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/displacement_result.dart';
import '../services/displacement_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import 'fault_diagnosis_page.dart';

/// STEP 8 — 변위 계산 (mock 진행 시뮬레이션).
/// (기존 Android: DisplacementActivity — 백그라운드로 변위 측정, 진행률 표시,
///  완료 후 추론 버튼 노출 → FaultDiagnosisActivity)
///
/// ⚠️ 실제 변위 계산은 미구현. 진행률은 시뮬레이션이며 결과는 mock 데이터.
class DisplacementPage extends StatefulWidget {
  const DisplacementPage({super.key});

  static const String routeName = '/displacement';

  @override
  State<DisplacementPage> createState() => _DisplacementPageState();
}

class _DisplacementPageState extends State<DisplacementPage> {
  double _progress = 0;
  bool _done = false;
  Timer? _timer;
  DisplacementResult? _result;

  @override
  void initState() {
    super.initState();
    _startMockMeasurement();
  }

  void _startMockMeasurement() {
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _progress += 0.08;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _done = true;
          _result = DisplacementService().mockResult();
          context.read<DiagnosisSession>().setDisplacementResult(_result!);
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('변위 계산')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 8,
              total: 9,
              title: '변위 계산 (DisplacementZ)',
              description: '마커 추적으로부터 변위를 계산합니다. (현재: mock 진행/데이터)',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_done) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text('변위 측정 중... ${(_progress * 100).toInt()}%'),
                    ] else ...[
                      Icon(Icons.check_circle,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 12),
                      Text('저장 완료! (${_result?.length ?? 0}개 데이터)'),
                      const SizedBox(height: 4),
                      Text('모델 입력 형상: [1, 1, 2048]',
                          style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: '진단하기',
              icon: Icons.analytics,
              onPressed: _done
                  ? () => Navigator.pushNamed(
                      context, FaultDiagnosisPage.routeName)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
