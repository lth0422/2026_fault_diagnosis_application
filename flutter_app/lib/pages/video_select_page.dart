import 'package:flutter/material.dart';

import '../widgets/step_header.dart';
import '../widgets/primary_button.dart';
import 'video_info_page.dart';

/// STEP 2 — 진단 대상 영상 선택 (플레이스홀더).
/// (기존 Android: MainActivity — 갤러리에서 영상 선택 후 VideoSizeActivity 로 이동)
class VideoSelectPage extends StatelessWidget {
  const VideoSelectPage({super.key});

  static const String routeName = '/video-select';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('영상 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StepHeader(
              step: 2,
              total: 9,
              title: '영상 선택',
              description: '갤러리에서 진단할 영상을 선택합니다. (실제 파일 선택은 이후 마일스톤에서 구현)',
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_outlined,
                        size: 72, color: theme.colorScheme.primary),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('갤러리에서 영상 선택'),
                      onPressed: () {
                        // 플레이스홀더: 실제 갤러리 연동은 미구현.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('영상 선택은 이후 마일스톤에서 구현됩니다.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            PrimaryButton(
              label: '다음',
              liftFromSystemNav: true,
              onPressed: () =>
                  Navigator.pushNamed(context, VideoInfoPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
