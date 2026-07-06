import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/diagnosis_result.dart';
import '../services/diagnosis_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/probability_bar.dart';
import 'start_page.dart';

/// STEP 9 — 결함 진단 결과 표시.
/// (기존 Android: FaultDiagnosisActivity — CSV의 DisplacementZ(2048) 로 PyTorch
///  Lite 모델 추론, softmax 확률 표시, 완료 시 Start 로 이동하며 스택 초기화)
/// 클래스 순서: B, H, IR, OR. (예상 결함: H=파랑, 그 외=빨강)
class FaultDiagnosisPage extends StatefulWidget {
  const FaultDiagnosisPage({super.key});

  static const String routeName = '/diagnosis';

  @override
  State<FaultDiagnosisPage> createState() => _FaultDiagnosisPageState();
}

class _FaultDiagnosisPageState extends State<FaultDiagnosisPage> {
  bool _isDiagnosing = false;
  DiagnosisResult? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _diagnose();
    });
  }

  /// 기존 Android 규칙: H 는 파란색, 그 외(B/IR/OR)는 빨간색.
  Color _labelColor(String label) =>
      label == 'H' ? const Color(0xFF1976D2) : const Color(0xFFD32F2F);

  Future<void> _diagnose() async {
    setState(() {
      _isDiagnosing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final session = context.read<DiagnosisSession>();
      final displacementZ = session.displacementResult?.displacementZ;
      if (displacementZ == null || displacementZ.isEmpty) {
        throw StateError('변위 데이터가 없습니다.');
      }

      final result = await DiagnosisService().diagnose(displacementZ);
      if (!mounted) {
        return;
      }
      session.setDiagnosisResult(result);
      setState(() {
        _result = result;
        _isDiagnosing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isDiagnosing = false;
        _errorMessage = '진단 실패: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<DiagnosisSession>();
    final result = _result;
    final displacement = session.displacementResult;
    final predictedColor = result == null
        ? theme.colorScheme.primary
        : _labelColor(result.predictedLabel);

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
              description: '내장 모델(Fwdcnn7.ptl)의 클래스별 확률(B, H, IR, OR)입니다.',
            ),
            if (_isDiagnosing) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('모델 추론 중...'),
                    ],
                  ),
                ),
              ),
            ] else if (_errorMessage != null) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _diagnose,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 진단'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (result != null) ...[
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
                  itemCount: result.classLabels.length + 1,
                  itemBuilder: (context, i) {
                    if (i < result.classLabels.length) {
                      return ProbabilityBar(
                        label: result.classLabels[i],
                        value: result.probabilities[i],
                        highlight: i == result.predictedIndex,
                      );
                    }

                    final logitsText = result.logits.isEmpty
                        ? '-'
                        : result.logits
                            .map((value) => value.toStringAsFixed(3))
                            .join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        '입력 품질: 검출 ${displacement?.detectedFrameCount ?? 0}/${displacement?.rawLength ?? 0}, '
                        '실패 ${displacement?.missedFrameCount ?? 0}, '
                        'Z 표준편차 ${(displacement?.zStdDev ?? 0).toStringAsFixed(3)}\n'
                        'logits(B,H,IR,OR): $logitsText',
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  },
                ),
              ),
            ],
            PrimaryButton(
              label: '완료',
              icon: Icons.check,
              liftFromSystemNav: true,
              onPressed: result != null
                  ? () {
                      context.read<DiagnosisSession>().reset();
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName(StartPage.routeName),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
