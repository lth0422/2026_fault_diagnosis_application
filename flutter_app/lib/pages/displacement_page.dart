import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/diagnosis_session.dart';
import '../models/displacement_result.dart';
import '../services/displacement_service.dart';
import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import '../widgets/top_notice.dart';
import 'fault_diagnosis_page.dart';

/// STEP 8 — 변위 계산.
/// (기존 Android: DisplacementActivity — 백그라운드로 변위 측정, 완료 후 추론 버튼 노출)
class DisplacementPage extends StatefulWidget {
  const DisplacementPage({super.key});

  static const String routeName = '/displacement';

  @override
  State<DisplacementPage> createState() => _DisplacementPageState();
}

class _DisplacementPageState extends State<DisplacementPage> {
  bool _isComputing = false;
  DisplacementResult? _result;
  DisplacementProgress? _progress;
  StreamSubscription<DisplacementProgress>? _progressSubscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _computeDisplacement();
    });
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    super.dispose();
  }

  Future<void> _computeDisplacement() async {
    final session = context.read<DiagnosisSession>();
    await _progressSubscription?.cancel();
    final service = DisplacementService();
    _progressSubscription = service.watchProgress().listen((progress) {
      if (!mounted) {
        return;
      }
      setState(() => _progress = progress);
    });

    setState(() {
      _isComputing = true;
      _errorMessage = null;
      _result = null;
      _progress = null;
    });

    try {
      final result = await service.computeDisplacement(session);
      if (!mounted) {
        return;
      }
      session.setDisplacementResult(result);
      setState(() {
        _result = result;
        _isComputing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isComputing = false;
        _errorMessage = '변위 계산 실패: $error';
      });
    } finally {
      await _progressSubscription?.cancel();
      _progressSubscription = null;
    }
  }

  Future<void> _shareCsv(DisplacementResult result) async {
    try {
      await DisplacementService().shareCsv(result);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showTopNotice(context, 'CSV 내보내기 실패: $error', icon: Icons.error_outline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result;

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
              description: 'OpenCV 마커 추적으로부터 모델 입력 변위를 계산합니다.',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isComputing) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      const Text('변위 측정 중...'),
                      const SizedBox(height: 12),
                      _progressPanel(theme),
                    ] else if (_errorMessage != null) ...[
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _computeDisplacement,
                        icon: const Icon(Icons.refresh),
                        label: const Text('다시 계산'),
                      ),
                    ] else if (result != null) ...[
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text('계산 완료! (${result.length}개 데이터)'),
                      const SizedBox(height: 4),
                      Text(
                        '모델 입력 형상: [1, 1, 2048]',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Z 범위: ${result.minValue.toStringAsFixed(2)} ~ ${result.maxValue.toStringAsFixed(2)} px',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '검출 ${result.detectedFrameCount}/${result.rawLength}, '
                        '실패 ${result.missedFrameCount}, '
                        'Z 표준편차 ${result.zStdDev.toStringAsFixed(3)}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      if (result.csvDisplayName != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'CSV 저장: ${result.csvDisplayName}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () => _shareCsv(result),
                          icon: const Icon(Icons.ios_share),
                          label: const Text('CSV 내보내기'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: '진단하기',
              icon: Icons.analytics,
              liftFromSystemNav: true,
              onPressed: result != null
                  ? () =>
                      Navigator.pushNamed(context, FaultDiagnosisPage.routeName)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressPanel(ThemeData theme) {
    final progress = _progress;
    if (progress == null) {
      return const SizedBox(
        width: 220,
        child: LinearProgressIndicator(),
      );
    }

    final percent = (progress.progress * 100).clamp(0, 100).toStringAsFixed(1);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          LinearProgressIndicator(value: progress.progress.clamp(0, 1)),
          const SizedBox(height: 8),
          Text(
            '$percent%  (${progress.processed}/${progress.total})',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            '검출 ${progress.detected}, 실패 ${progress.missed}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
