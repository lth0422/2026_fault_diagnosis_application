import 'package:flutter/material.dart';

import '../widgets/primary_button.dart';
import 'video_select_page.dart';

/// STEP 1 — 시작 화면 / 진입점.
/// (기존 Android: StartActivity)
class StartPage extends StatelessWidget {
  const StartPage({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('결함 진단')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Icon(Icons.build_circle_outlined,
                size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              '결함 진단 애플리케이션',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '영상 기반 변위 분석으로 결함을 진단합니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            PrimaryButton(
              label: '시작하기',
              icon: Icons.play_arrow,
              onPressed: () =>
                  Navigator.pushNamed(context, VideoSelectPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
