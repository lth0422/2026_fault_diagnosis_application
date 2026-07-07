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
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              sliver: SliverList.list(
                children: [
                  Icon(
                    Icons.precision_manufacturing_outlined,
                    size: 88,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '회전기계 베어링 결함 진단',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '동영상에서 마커 변위를 측정하고 내장 AI 모델로 결함을 진단합니다.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const _InfoCard(
                    title: '주요 기능',
                    children: [
                      _GuideItem(
                        icon: Icons.videocam_outlined,
                        text: '동영상 기반 변위 측정',
                      ),
                      _GuideItem(
                        icon: Icons.track_changes_outlined,
                        text: 'HSV 색상 범위 기반 마커 추적',
                      ),
                      _GuideItem(
                        icon: Icons.analytics_outlined,
                        text: 'CSV 저장 및 AI 기반 결함 진단',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _InfoCard(
                    title: '촬영 가이드',
                    children: [
                      _GuideItem(
                        icon: Icons.timer_outlined,
                        text: '동영상은 10초 이상 촬영해주세요.',
                      ),
                      _GuideItem(
                        icon: Icons.speed_outlined,
                        text: '정확한 진단을 위해 최소 2400프레임을 권장합니다.',
                      ),
                      _GuideItem(
                        icon: Icons.movie_filter_outlined,
                        text: 'MP4, AVI, MOV, MKV 형식의 영상을 사용할 수 있습니다.',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PrimaryButton(
                      label: '결함 진단 시작하기',
                      icon: Icons.play_arrow,
                      liftFromSystemNav: true,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        VideoSelectPage.routeName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _GuideItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _GuideItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
