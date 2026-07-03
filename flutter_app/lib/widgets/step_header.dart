import 'package:flutter/material.dart';

/// 각 단계 페이지 상단에 표시하는 헤더 위젯.
///
/// 단계 번호(STEP x / total), 제목, 설명을 보여준다.
class StepHeader extends StatelessWidget {
  final int step;
  final int total;
  final String title;
  final String description;

  const StepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step / $total',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: theme.textTheme.headlineSmall),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(description, style: theme.textTheme.bodyMedium),
        ],
        const Divider(height: 32),
      ],
    );
  }
}
