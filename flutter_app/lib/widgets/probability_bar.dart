import 'package:flutter/material.dart';

/// 클래스별 확률을 가로 막대로 표시하는 위젯.
///
/// FaultDiagnosisPage 에서 B, H, IR, OR 클래스 확률을 보여줄 때 사용한다.
class ProbabilityBar extends StatelessWidget {
  final String label;

  /// 0.0 ~ 1.0 범위의 확률.
  final double value;

  /// 최댓값(예측 클래스) 강조 여부.
  final bool highlight;

  const ProbabilityBar({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color =
        highlight ? theme.colorScheme.primary : theme.colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 16,
                backgroundColor: theme.colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              '${(value * 100).toStringAsFixed(1)}%',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
