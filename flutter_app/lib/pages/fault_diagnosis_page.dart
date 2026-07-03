import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/diagnosis_result.dart';
import '../services/diagnosis_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/probability_bar.dart';
import 'start_page.dart';

/// STEP 9 — 결함 진단 결과 표시 (mock 데이터).
/// (기존 Android: FaultDiagnosisActivity — CSV의 DisplacementZ(2048) 로 PyTorch
///  Lite 모델 추론, softmax 확률 표시, 완료 시 Start 로 이동하며 스택 초기화)
///
/// ⚠️ 실제 모델 추론은 미구현. DiagnosisService.mockResult() 사용.
/// 클래스 순서: B, H, IR, OR. (예상 결함: H=파랑, 그 외=빨강)
class FaultDiagnosisPage extends StatelessWidget {
  const FaultDiagnosisPage({super.key});

  static const String routeName = '/diagnosis';

  /// 기존 Android 규칙: H 는 파란색, 그 외(B/IR/OR)는 빨간색.
  Color _labelColor(String label) =>
      label == 'H' ? const Color(0xFF1976D2) : const Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final DiagnosisResult result = DiagnosisService().mockResult();
    final theme = Theme.of(context);
    final predictedColor = _labelColor(result.predictedLabel);

    return Scaffold(
      appBar: AppBar(title: const Text('결함 진단')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 9,
              total: 9,
              title: '결함 진단 결과',
              description: '클래스별 확률(B, H, IR, OR)입니다. (현재: mock 데이터)',
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('예상 결함', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${result.predictedLabel}  '
                      '${(result.confidence * 100).toStringAsFixed(2)}%',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: predictedColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('다른 결함 확률', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: result.classLabels.length,
                itemBuilder: (context, i) => ProbabilityBar(
                  label: result.classLabels[i],
                  value: result.probabilities[i],
                  highlight: i == result.predictedIndex,
                ),
              ),
            ),
            PrimaryButton(
              label: '완료',
              icon: Icons.check,
              liftFromSystemNav: true,
              onPressed: () {
                context.read<DiagnosisSession>().reset();
                Navigator.popUntil(
                  context,
                  ModalRoute.withName(StartPage.routeName),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
